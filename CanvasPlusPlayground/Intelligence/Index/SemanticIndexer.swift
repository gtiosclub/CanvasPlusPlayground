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

    private let chunker = Chunker()
    private var embedder: ChunkEmbedder?
    private var pending: Task<Report, Never>?

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
        for source in sources {
            do {
                try await index(source, with: embedder, into: &report)
            } catch {
                LoggerService.main.error("SemanticIndexer: indexing \(source.sourceID) failed: \(error)")
            }
        }

        do {
            try modelContext.save()
        } catch {
            LoggerService.main.error("SemanticIndexer: save failed: \(error)")
        }
        return report
    }

    private func index(_ source: IndexSource, with embedder: ChunkEmbedder, into report: inout Report) async throws {
        let chunks = source.chunks(using: chunker)
        let sourceID = source.sourceID
        let rows = try modelContext.fetch(FetchDescriptor<IndexedChunk>(predicate: #Predicate { $0.sourceID == sourceID }))

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
                guard currentHashes[chunk.ordinal] == chunk.contentHash else {
                    throw IndexerError.invalidKeep(ordinal: chunk.ordinal)
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
                row.update(chunk: chunk, courseID: source.courseID, vectorData: vectorData, vectorCount: vectorCount, modelVersion: embedder.modelVersion)
            } else {
                modelContext.insert(IndexedChunk(chunk: chunk, courseID: source.courseID, vectorData: vectorData, vectorCount: vectorCount, modelVersion: embedder.modelVersion))
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
        let sources = models.compactMap { ($0 as? any SemanticIndexable)?.indexSource }
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

        let report = await shared.index(sources)
        do {
            try await shared.prune(keeping: Set(sources.map(\.sourceID)))
        } catch {
            LoggerService.main.error("SemanticIndexer: prune failed: \(error)")
        }
        LoggerService.main.debug("SemanticIndexer: backfill \(sources.count) sources — \(String(describing: report))")
    }

    @MainActor
    private static func cachedSources<T: PersistentModel & SemanticIndexable>(_ type: T.Type, in context: ModelContext) -> [IndexSource] {
        ((try? context.fetch(FetchDescriptor<T>())) ?? []).compactMap(\.indexSource)
    }
}
