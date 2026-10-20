//
//  SemanticIndexer.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 10/19/26.
//

import Foundation
import SwiftData

/// Keeps the agent store's `IndexedChunk`s in step with cached Canvas content,
/// embedding only chunks whose text changed since they were last indexed.
@ModelActor
actor SemanticIndexer {
    enum ChunkAction: Equatable, Sendable {
        /// The row at this ordinal already holds this exact chunk.
        case keep
        /// The chunk's text exists at another ordinal; copy that row's vectors instead of re-embedding.
        case reuse(fromOrdinal: Int)
        case embed
    }

    struct Report: Equatable, Sendable {
        var kept = 0
        var reused = 0
        var embedded = 0
        var deleted = 0
    }

    struct Match: Equatable, Sendable {
        let sourceID: String
        let courseID: String?
        let ordinal: Int
        let headingPath: [String]
        let text: String
        let score: Float
    }

    struct StorageReport: Sendable, CustomStringConvertible {
        struct Usage: Sendable, Equatable {
            var chunks = 0
            var vectorBytes = 0
            var textBytes = 0
        }

        /// Keyed by course ID; content without a course is under `nil`.
        var byCourse: [String?: Usage] = [:]
        /// Size of the store file and its write-ahead log on disk; nil for in-memory stores.
        var storeFileBytes: Int?

        var total: Usage {
            byCourse.values.reduce(into: Usage()) {
                $0.chunks += $1.chunks
                $0.vectorBytes += $1.vectorBytes
                $0.textBytes += $1.textBytes
            }
        }

        var description: String {
            let megabytes = { (bytes: Int) in String(format: "%.2f MB", Double(bytes) / 1_048_576) }
            let courses = byCourse
                .sorted { $0.value.chunks > $1.value.chunks }
                .map { "\($0.key ?? "none"): \($0.value.chunks) chunks, \(megabytes($0.value.vectorBytes + $0.value.textBytes))" }
                .joined(separator: "; ")
            return "\(total.chunks) chunks, vectors \(megabytes(total.vectorBytes)), text \(megabytes(total.textBytes)), "
                + "on disk \(storeFileBytes.map(megabytes) ?? "n/a") — \(courses)"
        }
    }

    private let chunker = Chunker()
    private var embedder: ChunkEmbedder?
    private var pending: Task<Report, Never>?
    private var searchCaches: [Bool: SearchCache] = [:]

    private struct SearchCache {
        let index: SearchIndex
        let rows: [Match]
    }

    // Embeddings cost ~26 ms per chunk, so a first backfill runs for minutes; committing this
    // often means suspension or a crash loses at most a few seconds of work.
    private static let embeddedChunksPerSave = 25

    /// - Parameter sources: Snapshots of the content to index. Sources not listed are left untouched.
    /// - Returns: What changed. Runs are serialized, so concurrent callers never interleave on a source.
    @discardableResult
    func index(_ sources: [IndexSource]) async -> Report {
        let previous = pending
        let run = Task {
            _ = await previous?.value
            return await self.run(sources)
        }
        pending = run
        return await run.value
    }

    /// - Parameter sourceIDs: Every source that still exists. Rows for any other source are deleted.
    func prune(keeping sourceIDs: Set<String>) throws {
        let stale = try modelContext.fetch(FetchDescriptor<IndexedChunk>()).filter { !sourceIDs.contains($0.sourceID) }
        stale.forEach(modelContext.delete)
        try modelContext.save()
        searchCaches.removeAll()
    }

    /// - Returns: Chunk counts and payload bytes per course, plus the store's size on disk.
    func storageReport() throws -> StorageReport {
        var report = StorageReport()
        for row in try modelContext.fetch(FetchDescriptor<IndexedChunk>()) {
            report.byCourse[row.courseID, default: .init()].chunks += 1
            report.byCourse[row.courseID, default: .init()].vectorBytes += row.vectorData.count
            report.byCourse[row.courseID, default: .init()].textBytes += row.text.utf8.count
        }

        if let configuration = modelContainer.configurations.first, !configuration.isStoredInMemoryOnly {
            let path = configuration.url.path(percentEncoded: false)
            report.storeFileBytes = ["", "-wal"].reduce(0) { total, suffix in
                let size = (try? FileManager.default.attributesOfItem(atPath: path + suffix)[.size] as? Int) ?? nil
                return total + (size ?? 0)
            }
        }
        return report
    }

    /// - Parameters:
    ///   - query: Free-text question or keywords.
    ///   - courseID: Restricts results to one course; nil searches everything.
    ///   - limit: Maximum number of matches.
    ///   - meanCentered: Subtract the corpus centroid before scoring. Off only to measure its effect.
    /// - Returns: Best-scoring chunks first. Empty when the model is unavailable or nothing is indexed.
    func search(_ query: String, courseID: String? = nil, limit: Int = 5, meanCentered: Bool = true) async throws -> [Match] {
        guard limit > 0, let embedder = await loadedEmbedder() else { return [] }
        _ = await pending?.value

        let queryChunk = TextChunk(sourceID: "query", ordinal: 0, headingPath: [], text: query)
        guard let queryVector = Self.mean(try await embedder.vectors(for: queryChunk)) else { return [] }

        let cache = try searchCache(meanCentered: meanCentered, embedder: embedder)
        return cache.index
            .rank(query: queryVector) { courseID == nil || cache.rows[$0].courseID == courseID }
            .prefix(limit)
            .map { index, score in
                let row = cache.rows[index]
                return Match(sourceID: row.sourceID, courseID: row.courseID, ordinal: row.ordinal, headingPath: row.headingPath, text: row.text, score: score)
            }
    }

    /// Scores each candidate by its best vector's cosine similarity to the query.
    ///
    /// - Parameters:
    ///   - query: The query vector.
    ///   - candidates: Each candidate's vectors (usually one; more when a chunk was split for truncation).
    ///   - centroid: Subtracted from every vector before scoring, or nil to score raw vectors.
    /// - Returns: Indices into `candidates` with their scores, best first. Candidates without
    ///   a vector matching the query's dimension are omitted.
    static func rank(query: [Float], candidates: [[[Float]]], centroid: [Float]?) -> [(index: Int, score: Float)] {
        SearchIndex(candidates: candidates, centroid: centroid, dimension: query.count).rank(query: query)
    }

    /// - Parameter vectors: Vectors of equal length.
    /// - Returns: Their element-wise mean, or nil when there are none.
    static func mean(_ vectors: [[Float]]) -> [Float]? {
        let nonEmpty = vectors.filter { !$0.isEmpty }
        guard let dimension = nonEmpty.first?.count else { return nil }

        var sum = [Double](repeating: 0, count: dimension)
        for vector in nonEmpty where vector.count == dimension {
            for index in 0..<dimension {
                sum[index] += Double(vector[index])
            }
        }
        return sum.map { Float($0 / Double(nonEmpty.count)) }
    }

    // Built from the store once, then reused until a write clears it.
    private func searchCache(meanCentered: Bool, embedder: ChunkEmbedder) throws -> SearchCache {
        if let cached = searchCaches[meanCentered] { return cached }

        let stored = try modelContext.fetch(FetchDescriptor<IndexedChunk>()).filter { $0.isEmbedded(by: embedder.modelVersion) }
        let vectors = stored.map(\.vectors)
        let centroid = meanCentered ? Self.mean(vectors.flatMap { $0 }) : nil
        let cache = SearchCache(
            index: SearchIndex(candidates: vectors, centroid: centroid, dimension: embedder.dimension),
            rows: stored.map { Match(sourceID: $0.sourceID, courseID: $0.courseID, ordinal: $0.ordinal, headingPath: $0.headingPath, text: $0.text, score: 0) }
        )
        searchCaches[meanCentered] = cache
        return cache
    }

    /// - Parameter sources: A batch that may list the same source more than once.
    /// - Returns: One source per `sourceID`, in first-seen order, carrying the last snapshot of each.
    static func uniqued(_ sources: [IndexSource]) -> [IndexSource] {
        let latest = Dictionary(sources.map { ($0.sourceID, $0) }, uniquingKeysWith: { _, last in last })
        var seen = Set<String>()
        return sources.compactMap { seen.insert($0.sourceID).inserted ? latest[$0.sourceID] : nil }
    }

    /// Decides, per incoming chunk, whether its stored vectors can be kept, reused, or must be recomputed.
    ///
    /// - Parameters:
    ///   - existingHashes: Content hash of each stored row, by ordinal. Rows embedded by an older model are excluded.
    ///   - incomingHashes: Content hash of each new chunk, in ordinal order.
    /// - Returns: One action per incoming chunk, in the same order. Stored ordinals at or past
    ///   `incomingHashes.count` are deleted by the caller.
    static func plan(existingHashes: [Int: String], incomingHashes: [String]) -> [ChunkAction] {
        // Lowest ordinal wins for duplicate text, so the same input always produces the same plan.
        var ordinalByHash: [String: Int] = [:]
        for (ordinal, hash) in existingHashes.sorted(by: { $0.key < $1.key }) where ordinalByHash[hash] == nil {
            ordinalByHash[hash] = ordinal
        }

        return incomingHashes.enumerated().map { ordinal, hash in
            if existingHashes[ordinal] == hash {
                return .keep
            }
            if let storedOrdinal = ordinalByHash[hash] {
                return .reuse(fromOrdinal: storedOrdinal)
            }
            return .embed
        }
    }

    private func run(_ sources: [IndexSource]) async -> Report {
        guard let embedder = await loadedEmbedder() else { return Report() }

        var report = Report()
        var embeddedAtLastSave = 0
        for source in Self.uniqued(sources) {
            do {
                try await index(source, with: embedder, into: &report)
            } catch {
                LoggerService.main.error("SemanticIndexer: indexing \(source.sourceID) failed: \(error)")
            }
            if report.embedded - embeddedAtLastSave >= Self.embeddedChunksPerSave {
                save()
                embeddedAtLastSave = report.embedded
            }
        }

        save()
        if report.embedded + report.reused + report.deleted > 0 {
            searchCaches.removeAll()
        }
        return report
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            LoggerService.main.error("SemanticIndexer: save failed: \(error)")
        }
    }

    private func index(_ source: IndexSource, with embedder: ChunkEmbedder, into report: inout Report) async throws {
        let sourceID = source.sourceID
        let rows = try modelContext.fetch(FetchDescriptor<IndexedChunk>(predicate: #Predicate { $0.sourceID == sourceID }))

        // Skipping before chunks(using:) matters for files: it avoids re-extracting every PDF on each backfill.
        if let revision = source.revision, !rows.isEmpty,
           rows.allSatisfy({ $0.sourceRevision == revision && $0.isEmbedded(by: embedder.modelVersion) }) {
            report.kept += rows.count
            return
        }

        let chunks = source.chunks(using: chunker)
        let rowsByOrdinal = Dictionary(rows.map { ($0.ordinal, $0) }, uniquingKeysWith: { first, _ in first })
        let current = rows.filter { $0.isEmbedded(by: embedder.modelVersion) }
        let currentHashes = Dictionary(current.map { ($0.ordinal, $0.contentHash) }, uniquingKeysWith: { first, _ in first })
        // Snapshot before any row is overwritten, since a reused vector may come from a row updated earlier in the loop.
        let currentVectors = Dictionary(current.map { ($0.ordinal, ($0.vectorData, $0.vectorCount)) }, uniquingKeysWith: { first, _ in first })

        let actions = Self.plan(existingHashes: currentHashes, incomingHashes: chunks.map(\.contentHash))
        guard actions.count == chunks.count else {
            throw IndexerError.planMismatch(expected: chunks.count, got: actions.count)
        }

        for (chunk, action) in zip(chunks, actions) {
            let vectorData: Data
            let vectorCount: Int

            switch action {
            case .keep:
                guard currentHashes[chunk.ordinal] == chunk.contentHash, let row = rowsByOrdinal[chunk.ordinal] else {
                    throw IndexerError.invalidKeep(ordinal: chunk.ordinal)
                }
                if row.sourceRevision != source.revision {
                    row.sourceRevision = source.revision
                }
                report.kept += 1
                continue
            case .reuse(let ordinal):
                guard let stored = currentVectors[ordinal], currentHashes[ordinal] == chunk.contentHash else {
                    throw IndexerError.invalidReuse(ordinal: ordinal)
                }
                (vectorData, vectorCount) = stored
                report.reused += 1
            case .embed:
                (vectorData, vectorCount) = IndexedChunk.encode(try await embedder.vectors(for: chunk))
                report.embedded += 1
            }

            if let row = rowsByOrdinal[chunk.ordinal] {
                row.update(chunk: chunk, courseID: source.courseID, sourceRevision: source.revision, vectorData: vectorData, vectorCount: vectorCount, modelVersion: embedder.modelVersion)
            } else {
                modelContext.insert(IndexedChunk(chunk: chunk, courseID: source.courseID, sourceRevision: source.revision, vectorData: vectorData, vectorCount: vectorCount, modelVersion: embedder.modelVersion))
            }
        }

        for row in rows where row.ordinal >= chunks.count {
            modelContext.delete(row)
            report.deleted += 1
        }
    }

    private func loadedEmbedder() async -> ChunkEmbedder? {
        if let embedder { return embedder }
        do {
            let loaded = try ChunkEmbedder()
            try await loaded.load()
            embedder = loaded
            return loaded
        } catch {
            LoggerService.main.error("SemanticIndexer: embedding model unavailable: \(error)")
            return nil
        }
    }

    enum IndexerError: Error {
        case planMismatch(expected: Int, got: Int)
        case invalidKeep(ordinal: Int)
        case invalidReuse(ordinal: Int)
    }
}

// MARK: - App integration

extension SemanticIndexer {
    static let shared: SemanticIndexer? = {
        do {
            return SemanticIndexer(modelContainer: try .makeAgentContainer())
        } catch {
            LoggerService.main.error("SemanticIndexer: agent store unavailable: \(error)")
            return nil
        }
    }()

    /// Called after every cached sync. Snapshots indexable models on the main actor, then indexes in the background.
    @MainActor
    static func enqueue(_ models: [some PersistentModel]) {
        let context = ModelContext.shared
        let sources = models.compactMap { ($0 as? any SemanticIndexable)?.indexSource(in: context) }
        enqueue(excludingRetired(sources, retiredCourseIDs: retiredCourseIDs(in: context)))
    }

    /// - Parameter sources: Already-snapshotted sources, e.g. a file right after it was downloaded.
    @MainActor
    static func enqueue(_ sources: [IndexSource]) {
        guard !sources.isEmpty, let shared else { return }

        Task.detached(priority: .utility) {
            await shared.index(sources)
        }
    }

    /// Indexes everything already cached and removes rows for content that no longer exists.
    /// Unchanged content costs only chunking and a hash comparison.
    @MainActor
    static func backfill() async {
        guard let shared else { return }
        let context = ModelContext.shared

        var sources: [IndexSource] = []
        sources += cachedSources(Page.self, in: context)
        sources += cachedSources(Announcement.self, in: context)
        sources += cachedSources(DiscussionTopic.self, in: context)
        sources += cachedSources(Assignment.self, in: context)
        sources += cachedSources(Quiz.self, in: context)
        sources += cachedSources(Course.self, in: context)
        sources += cachedSources(File.self, in: context)
        // Retired courses drop out here, and prune then deletes their existing rows.
        sources = excludingRetired(sources, retiredCourseIDs: retiredCourseIDs(in: context))

        let report = await shared.index(sources)
        do {
            try await shared.prune(keeping: Set(sources.map(\.sourceID)))
        } catch {
            LoggerService.main.error("SemanticIndexer: prune failed: \(error)")
        }
        LoggerService.main.debug("SemanticIndexer: backfill \(sources.count) sources — \(String(describing: report))")
        if let storage = try? await shared.storageReport() {
            LoggerService.main.debug("SemanticIndexer: storage \(storage)")
        }
    }

    /// Whether a course's content should leave the index. Its rows are deleted at the next backfill,
    /// and syncs stop re-adding them.
    ///
    /// - Parameter course: A cached course, read on the main actor.
    @MainActor
    static func isRetired(_ course: Course) -> Bool {
        if course.isCourseDeleted { return true }
        return !course.isFavorite && !course.hasActiveEnrollment &&
            (course.isPastEnrollment || course.concluded == true)
    }

    /// - Parameters:
    ///   - sources: Candidate sources.
    ///   - retiredCourseIDs: Courses whose content should not be indexed.
    /// - Returns: The sources that belong to no course or to a course that isn't retired.
    static func excludingRetired(_ sources: [IndexSource], retiredCourseIDs: Set<String>) -> [IndexSource] {
        sources.filter { source in source.courseID.map { !retiredCourseIDs.contains($0) } ?? true }
    }

    @MainActor
    private static func retiredCourseIDs(in context: ModelContext) -> Set<String> {
        Set(((try? context.fetch(FetchDescriptor<Course>())) ?? []).filter(isRetired).map(\.id))
    }

    @MainActor
    private static func cachedSources<T: PersistentModel & SemanticIndexable>(_ type: T.Type, in context: ModelContext) -> [IndexSource] {
        ((try? context.fetch(FetchDescriptor<T>())) ?? []).compactMap { $0.indexSource(in: context) }
    }
}
