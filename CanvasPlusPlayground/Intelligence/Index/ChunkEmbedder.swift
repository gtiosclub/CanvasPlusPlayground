//
//  ChunkEmbedder.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 10/18/26.
//

import Foundation
import NaturalLanguage

/// Turns `TextChunk`s into sentence-level vectors with `NLContextualEmbedding`.
/// Runs without Apple Intelligence; needs only the embedding assets, which `load()` requests.
actor ChunkEmbedder {
    struct TokenVector: Sendable {
        let values: [Double]
        /// False for the model's marker tokens, which have an empty range in the input.
        let coversText: Bool
    }

    /// Vectors from different model versions aren't comparable, so the index stores this with each vector.
    struct ModelVersion: Hashable, Codable, Sendable {
        let identifier: String
        let revision: Int
    }

    enum EmbedderError: Error {
        case unsupportedLanguage(NLLanguage)
        case assetsUnavailable
    }

    nonisolated let modelVersion: ModelVersion
    nonisolated let dimension: Int

    private let embedding: NLContextualEmbedding
    private let language: NLLanguage

    /// - Parameter language: Language passed to the model. All Canvas content is embedded as English for now.
    init(language: NLLanguage = .english) throws {
        guard let embedding = NLContextualEmbedding(language: language) else {
            throw EmbedderError.unsupportedLanguage(language)
        }
        self.embedding = embedding
        self.language = language
        modelVersion = ModelVersion(identifier: embedding.modelIdentifier, revision: embedding.revision)
        dimension = embedding.dimension
    }

    /// Downloads the model assets if needed and loads the model. Call before `vectors(for:)`.
    func load() async throws {
        if !embedding.hasAvailableAssets {
            guard try await embedding.requestAssets() == .available else {
                throw EmbedderError.assetsUnavailable
            }
        }
        try embedding.load()
    }

    /// - Parameter chunk: The chunk to embed, including its heading prefix.
    /// - Returns: One vector per piece of the chunk. Usually a single vector; more than one only when
    ///   the chunk exceeded the model's input limit and had to be split to avoid silent truncation.
    func vectors(for chunk: TextChunk) throws -> [[Float]] {
        try vectors(for: chunk.text, prefix: TextChunk.headingPrefix(for: chunk.headingPath))
    }

    private func vectors(for text: String, prefix: String) throws -> [[Float]] {
        let input = prefix + text
        let result = try embedding.embeddingResult(for: input, language: language)

        // A truncated result reports maximumSequenceLength - 1; an exact fit is split too, harmlessly.
        if result.sequenceLength >= embedding.maximumSequenceLength - 1, let (first, second) = Self.halve(text) {
            return try vectors(for: first, prefix: prefix) + vectors(for: second, prefix: prefix)
        }

        var tokens: [TokenVector] = []
        result.enumerateTokenVectors(in: input.startIndex..<input.endIndex) { values, range in
            tokens.append(TokenVector(values: values, coversText: !range.isEmpty))
            return true
        }
        return [Self.pool(tokens)]
    }

    /// Splits at the sentence boundary nearest the middle, falling back to the nearest whitespace.
    /// Returns nil when the text is a single word and can't be split further.
    static func halve(_ text: String) -> (String, String)? {
        let middle = text.index(text.startIndex, offsetBy: text.count / 2)

        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        let sentenceStarts = tokenizer.tokens(for: text.startIndex..<text.endIndex)
            .map(\.lowerBound)
            .filter { $0 > text.startIndex }
        let wordStarts = text.indices.filter { $0 > text.startIndex && text[text.index(before: $0)].isWhitespace }

        let candidates = sentenceStarts.isEmpty ? wordStarts : sentenceStarts
        guard let split = candidates.min(by: {
            abs(text.distance(from: middle, to: $0)) < abs(text.distance(from: middle, to: $1))
        }) else { return nil }

        let first = text[..<split].trimmingCharacters(in: .whitespacesAndNewlines)
        let second = text[split...].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !first.isEmpty, !second.isEmpty else { return nil }
        return (first, second)
    }

    /// Combines the model's per-token vectors into one vector for the whole input.
    ///
    /// - Parameter tokens: Every token vector the model produced, in order, including marker tokens.
    /// - Returns: A single vector of `dimension` values, ready to store and compare.
    static func pool(_ tokens: [TokenVector]) -> [Float] {
        let filteredTokens: [TokenVector] = tokens.filter { $0.coversText }
        guard !filteredTokens.isEmpty else {
            return []
        }

        let vectorDimension: Int = filteredTokens[0].values.count
        var nonScaledPool = [Double](repeating: 0, count: vectorDimension)

        for token in filteredTokens {
            for dimensionIndex in 0..<vectorDimension {
                nonScaledPool[dimensionIndex] += token.values[dimensionIndex]
            }
        }

        let lenNonScaledPool: Double = nonScaledPool.reduce(0.0) { $0 + $1 * $1 }.squareRoot()

        guard lenNonScaledPool != 0 else {
            return []
        }

        return nonScaledPool.map { Float($0 / lenNonScaledPool) }
    }
}
