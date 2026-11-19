//
//  LexicalIndex.swift
//  CanvasPlusPlayground
//

import Foundation

/// BM25 keyword search over a fixed set of documents.
///
/// Semantic search is good at "what's the late policy" but weak at exact tokens like "CS 1331",
/// "PS5" or "Lab 2". This index keeps those findable; `RankFusion` merges the two rankings.
/// Pure Swift, so it works with no model and no embedding assets.
struct LexicalIndex: Sendable {
    /// Term-frequency saturation. 1.2 is the usual default.
    var k1 = 1.2
    /// Length normalization. 0.75 is the usual default.
    var b = 0.75

    private let termFrequencies: [[String: Int]]
    private let lengths: [Int]
    private let averageLength: Double
    private let documentFrequency: [String: Int]

    var count: Int { lengths.count }

    init(documents: [String]) {
        termFrequencies = documents.map { document in
            Self.tokens(in: document).reduce(into: [:]) { $0[$1, default: 0] += 1 }
        }
        lengths = termFrequencies.map { $0.values.reduce(0, +) }
        averageLength = lengths.isEmpty ? 0 : Double(lengths.reduce(0, +)) / Double(lengths.count)
        documentFrequency = termFrequencies.reduce(into: [:]) { result, terms in
            for term in terms.keys { result[term, default: 0] += 1 }
        }
    }

    /// - Parameters:
    ///   - query: Free text. Repeated words count once.
    ///   - isIncluded: Decides by document index which documents may appear.
    /// - Returns: Documents that share at least one term with the query, best first; ties keep document order.
    func rank(_ query: String, where isIncluded: (Int) -> Bool = { _ in true }) -> [(index: Int, score: Double)] {
        let terms = Set(Self.tokens(in: query))
        guard !terms.isEmpty, averageLength > 0 else { return [] }

        let total = Double(count)
        var scores: [(index: Int, score: Double)] = []

        for (index, frequencies) in termFrequencies.enumerated() where isIncluded(index) {
            var score = 0.0
            for term in terms {
                guard let frequency = frequencies[term], let containing = documentFrequency[term] else { continue }
                // BM25+ style IDF that never goes negative for very common terms.
                let idf = log(1 + (total - Double(containing) + 0.5) / (Double(containing) + 0.5))
                let tf = Double(frequency)
                let norm = 1 - b + b * Double(lengths[index]) / averageLength
                score += idf * (tf * (k1 + 1)) / (tf + k1 * norm)
            }
            if score > 0 { scores.append((index, score)) }
        }

        return scores.sorted { $0.score != $1.score ? $0.score > $1.score : $0.index < $1.index }
    }

    /// Lowercased letter/digit runs. A run that mixes letters and digits ("ps5", "cs1331") also adds
    /// its letter and digit parts, so "CS1331" matches "CS 1331" and the other way round.
    static func tokens(in text: String) -> [String] {
        var tokens: [String] = []

        for word in text.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }) {
            let word = String(word)
            guard !stopWords.contains(word) else { continue }
            tokens.append(word)

            let parts = splitLettersAndDigits(word)
            if parts.count > 1 {
                tokens += parts.filter { !stopWords.contains($0) }
            }
        }

        return tokens
    }

    private static func splitLettersAndDigits(_ word: String) -> [String] {
        var parts: [String] = []
        var current = ""
        var currentIsDigit: Bool?

        for character in word {
            let isDigit = character.isNumber
            if let currentIsDigit, currentIsDigit != isDigit {
                parts.append(current)
                current = ""
            }
            current.append(character)
            currentIsDigit = isDigit
        }
        if !current.isEmpty { parts.append(current) }
        return parts
    }

    /// Only the most common function words. BM25's IDF already discounts frequent terms, so
    /// this list is short on purpose: dropping "due" or "week" would hurt course questions.
    private static let stopWords: Set<String> = [
        "a", "an", "the", "and", "or", "of", "to", "in", "on", "for", "is", "are", "be", "it",
        "this", "that", "with", "as", "at", "by", "what", "when", "where", "how", "do", "does", "i", "my"
    ]
}

/// Reciprocal-rank fusion: merges rankings that use incomparable scores (BM25 vs cosine) using
/// only each item's position. An item ranked well by either list ends up near the top.
enum RankFusion {
    /// The usual RRF constant. Larger values flatten the advantage of the very top ranks.
    static let defaultK = 60.0

    /// - Parameter rankings: Each ranking best first. An item missing from a ranking adds nothing for it.
    /// - Returns: Every item that appears in any ranking with its fused score, best first. Ties go to
    ///   the item that first appears earliest, reading the rankings in order.
    static func fuse<Key: Hashable>(_ rankings: [[Key]], k: Double = defaultK) -> [(key: Key, score: Double)] {
        var scores: [Key: Double] = [:]
        var firstSeen: [Key: Int] = [:]
        var order = 0

        for ranking in rankings {
            for (rank, key) in ranking.enumerated() {
                scores[key, default: 0] += 1 / (k + Double(rank + 1))
                if firstSeen[key] == nil {
                    firstSeen[key] = order
                    order += 1
                }
            }
        }

        return scores
            .map { (key: $0.key, score: $0.value) }
            .sorted { $0.score != $1.score ? $0.score > $1.score : firstSeen[$0.key]! < firstSeen[$1.key]! }
    }
}

/// Ranks a handful of passages that aren't in the semantic index (e.g. a syllabus the student just
/// picked) with the same hybrid recipe: BM25 always, plus embeddings when the model is available.
enum PassageRetriever {
    /// - Parameters:
    ///   - passages: Candidate passages.
    ///   - query: What to look for.
    ///   - limit: Maximum number of passages returned.
    ///   - embedder: A loaded embedder, or nil for keyword-only ranking.
    /// - Returns: Indices into `passages`, best matches first, then the rest in document order,
    ///   up to `limit`.
    static func rank(
        _ passages: [String],
        for query: String,
        limit: Int,
        embedder: ChunkEmbedder?
    ) async -> [Int] {
        guard limit > 0, !passages.isEmpty else { return [] }

        let lexical = LexicalIndex(documents: passages).rank(query).map(\.index)
        var rankings = [lexical]

        if let embedder, let semantic = try? await semanticRanking(passages, query: query, embedder: embedder) {
            rankings.insert(semantic, at: 0)
        }

        let fused = RankFusion.fuse(rankings).map(\.key)
        // Fill up to `limit` with the rest in document order, so the caller always gets as much
        // context as it asked for (and something, even when nothing matched).
        let matched = Set(fused)
        let ranked = fused + passages.indices.filter { !matched.contains($0) }
        return Array(ranked.prefix(limit))
    }

    private static func semanticRanking(_ passages: [String], query: String, embedder: ChunkEmbedder) async throws -> [Int] {
        let queryChunk = TextChunk(sourceID: "query", ordinal: 0, headingPath: [], text: query)
        guard let queryVector = SemanticIndexer.mean(try await embedder.vectors(for: queryChunk)) else { return [] }

        var candidates: [[[Float]]] = []
        for (ordinal, passage) in passages.enumerated() {
            let chunk = TextChunk(sourceID: "passage", ordinal: ordinal, headingPath: [], text: passage)
            candidates.append(try await embedder.vectors(for: chunk))
        }

        return SemanticIndexer.rank(query: queryVector, candidates: candidates, centroid: nil).map(\.index)
    }

    /// A loaded embedder, or nil when the embedding assets aren't available within `timeout`
    /// (a first-time asset download can take much longer than a student should wait).
    static func loadEmbedder(timeout: Duration = .seconds(5)) async -> ChunkEmbedder? {
        guard let embedder = try? ChunkEmbedder() else { return nil }

        // Not a task group: a group waits for every child, and asset loading may not stop when cancelled.
        return await withCheckedContinuation { continuation in
            let once = ResumeOnce()
            Task {
                let loaded: ChunkEmbedder? = (try? await embedder.load()).map { embedder }
                if once.claim() { continuation.resume(returning: loaded) }
            }
            Task {
                try? await Task.sleep(for: timeout)
                if once.claim() { continuation.resume(returning: nil) }
            }
        }
    }
}

/// Lets exactly one of several racing tasks resume a continuation.
private final class ResumeOnce: @unchecked Sendable {
    private let lock = NSLock()
    private var claimed = false

    func claim() -> Bool {
        lock.withLock {
            defer { claimed = true }
            return !claimed
        }
    }
}
