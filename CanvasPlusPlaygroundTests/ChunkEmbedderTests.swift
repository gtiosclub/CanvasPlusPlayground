//
//  ChunkEmbedderTests.swift
//  CanvasPlusPlaygroundTests
//
//  Created by Kareem Alaiwat on 10/18/26.
//

import NaturalLanguage
import Testing
@testable import CanvasPlusPlayground

struct ChunkEmbedderHalveTests {
    @Test func splitsAtTheSentenceBoundaryNearestTheMiddle() throws {
        let (first, second) = try #require(ChunkEmbedder.halve("One two. Three four. Five six. Seven eight."))
        #expect(first == "One two. Three four.")
        #expect(second == "Five six. Seven eight.")
    }

    @Test func keepsLineBreaksBetweenBlocks() throws {
        let (first, second) = try #require(ChunkEmbedder.halve("Exam 1 – Oct 3\nExam 2 – Nov 7"))
        #expect(first == "Exam 1 – Oct 3")
        #expect(second == "Exam 2 – Nov 7")
    }

    @Test func fallsBackToWhitespaceForASingleSentence() throws {
        let (first, second) = try #require(ChunkEmbedder.halve("alpha beta gamma delta"))
        #expect(first == "alpha beta")
        #expect(second == "gamma delta")
    }

    @Test(arguments: ["", "word", "   "])
    func cannotSplitASingleWord(text: String) {
        #expect(ChunkEmbedder.halve(text) == nil)
    }
}

struct ChunkEmbedderPoolTests {
    typealias Token = ChunkEmbedder.TokenVector

    private static func isClose(_ lhs: [Float], _ rhs: [Float], tolerance: Float = 1e-6) -> Bool {
        lhs.count == rhs.count && zip(lhs, rhs).allSatisfy { abs($0 - $1) <= tolerance }
    }

    private static func length(_ vector: [Float]) -> Float {
        vector.reduce(0) { $0 + $1 * $1 }.squareRoot()
    }

    @Test func averagesTextTokensAndNormalizes() {
        let pooled = ChunkEmbedder.pool([
            Token(values: [3, 0, 0], coversText: true),
            Token(values: [0, 4, 0], coversText: true),
        ])
        #expect(Self.isClose(pooled, [0.6, 0.8, 0]))
    }

    @Test func ignoresMarkerTokens() {
        let pooled = ChunkEmbedder.pool([
            Token(values: [0, 0, 100], coversText: false),
            Token(values: [1, 0, 0], coversText: true),
            Token(values: [-50, 9, 9], coversText: false),
        ])
        #expect(Self.isClose(pooled, [1, 0, 0]))
    }

    @Test func takesTheDimensionFromTheTokens() {
        #expect(ChunkEmbedder.pool([Token(values: [1, 1], coversText: true)]).count == 2)
    }

    @Test func repeatingTokensDoesNotChangeTheResult() {
        let first = Token(values: [1, 2, 3], coversText: true)
        let second = Token(values: [-2, 0.5, 4], coversText: true)
        #expect(Self.isClose(ChunkEmbedder.pool([first, second]), ChunkEmbedder.pool([first, second, first, second])))
    }

    @Test func returnsUnitLengthVectorsForModelSizedInput() {
        var rng = SeededGenerator(seed: 512)

        for _ in 0..<200 {
            let tokens = (0..<Int.random(in: 1...255, using: &rng)).map { index in
                Token(
                    values: (0..<512).map { _ in Double.random(in: -3...3, using: &rng) },
                    coversText: index != 0
                )
            }
            let pooled = ChunkEmbedder.pool(tokens)
            guard tokens.count > 1 else {
                #expect(pooled.isEmpty)
                continue
            }
            #expect(pooled.count == 512)
            #expect(abs(Self.length(pooled) - 1) < 1e-5)
        }
    }

    @Test(arguments: [
        [],
        [Token(values: [1, 2, 3], coversText: false)],
        [Token(values: [0, 0, 0], coversText: true)],
        [Token(values: [1, -2], coversText: true), Token(values: [-1, 2], coversText: true)],
    ] as [[Token]])
    func returnsEmptyWhenThereIsNothingToAverage(tokens: [Token]) {
        #expect(ChunkEmbedder.pool(tokens).isEmpty)
    }
}

// Requires the on-device embedding assets; skipped rather than downloading them during a test run.
@Suite(.enabled(if: NLContextualEmbedding(language: .english)?.hasAvailableAssets ?? false))
struct ChunkEmbedderModelTests {
    @Test func reportsModelVersionAndDimension() throws {
        let embedder = try ChunkEmbedder()
        #expect(embedder.dimension == 512)
        #expect(!embedder.modelVersion.identifier.isEmpty)
    }

    @Test func embedsAShortChunkAsOneVector() async throws {
        let embedder = try ChunkEmbedder()
        try await embedder.load()

        let chunk = TextChunk(sourceID: "page:1", ordinal: 0, headingPath: ["Syllabus"], text: "Exam 1 – Oct 3")
        #expect(try await embedder.vectors(for: chunk).count == 1)
    }

    @Test func splitsAChunkTheModelWouldTruncate() async throws {
        let embedder = try ChunkEmbedder()
        try await embedder.load()

        let sentence = "Students submit the lab report through Canvas before the deadline."
        let text = Array(repeating: sentence, count: 40).joined(separator: " ")
        let chunk = TextChunk(sourceID: "page:1", ordinal: 0, headingPath: [], text: text)

        // 40 sentences ≈ 720 real tokens, so at least three pieces under the 256 limit.
        #expect(try await embedder.vectors(for: chunk).count >= 3)
    }

    @Test func producesFiniteUnitLengthVectorsOfTheModelDimension() async throws {
        let embedder = try ChunkEmbedder()
        try await embedder.load()

        let chunks = Chunker().chunks(fromHTML: ChunkerTests.syllabus, sourceID: "page:1", title: "Syllabus")
        for chunk in chunks {
            for vector in try await embedder.vectors(for: chunk) {
                #expect(vector.count == embedder.dimension)
                let isFinite = vector.allSatisfy(\.isFinite)
                #expect(isFinite)
                #expect(abs(vector.reduce(0) { $0 + $1 * $1 }.squareRoot() - 1) < 1e-5)
            }
        }
    }

    @Test func embeddingIsDeterministic() async throws {
        let embedder = try ChunkEmbedder()
        try await embedder.load()

        let chunk = TextChunk(sourceID: "page:1", ordinal: 0, headingPath: ["Grading"], text: "Homework is worth 40%.")
        let first = try await embedder.vectors(for: chunk)
        let second = try await embedder.vectors(for: chunk)
        #expect(first == second)
    }

    // RAGSystem's averaged word vectors embed these identically.
    @Test func wordOrderChangesTheVector() async throws {
        let embedder = try ChunkEmbedder()
        try await embedder.load()

        let before = TextChunk(sourceID: "a", ordinal: 0, headingPath: [], text: "The assignment is due before the exam.")
        let after = TextChunk(sourceID: "b", ordinal: 0, headingPath: [], text: "The exam is due before the assignment.")
        let beforeVector = try await embedder.vectors(for: before)[0]
        let afterVector = try await embedder.vectors(for: after)[0]
        let similarity = zip(beforeVector, afterVector).reduce(Float(0)) { $0 + $1.0 * $1.1 }

        #expect(similarity < 0.9999)
    }

    @Test func headingPathChangesTheVector() async throws {
        let embedder = try ChunkEmbedder()
        try await embedder.load()

        let exams = TextChunk(sourceID: "a", ordinal: 0, headingPath: ["Exams"], text: "Worth 20% each.")
        let homework = TextChunk(sourceID: "a", ordinal: 0, headingPath: ["Homework"], text: "Worth 20% each.")
        let examsVectors = try await embedder.vectors(for: exams)
        let homeworkVectors = try await embedder.vectors(for: homework)
        #expect(examsVectors != homeworkVectors)
    }

    @Test func measuredTokenCountsStillMatchTheModel() throws {
        let embedding = try #require(NLContextualEmbedding(language: .english))
        try embedding.load()

        for (text, tokens) in ChunkerTests.measuredTokenCounts {
            let result = try embedding.embeddingResult(for: text, language: .english)
            #expect(result.sequenceLength == tokens, "\(text) — re-measure if the model revision changed")
        }
    }
}
