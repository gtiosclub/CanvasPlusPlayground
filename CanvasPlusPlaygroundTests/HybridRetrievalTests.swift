//
//  HybridRetrievalTests.swift
//  CanvasPlusPlaygroundTests
//

import Foundation
import SwiftData
import Testing
@testable import CanvasPlusPlayground

struct LexicalIndexTokenTests {
    @Test(arguments: [
        ("CS 1331", ["cs", "1331"]),
        ("CS1331", ["cs1331", "cs", "1331"]),
        ("PS5 is due", ["ps5", "ps", "5", "due"]),
        ("The Late-Policy", ["late", "policy"]),
        ("", [])
    ])
    func tokenizes(_ text: String, expected: [String]) {
        #expect(LexicalIndex.tokens(in: text) == expected)
    }
}

struct LexicalIndexRankingTests {
    let documents = [
        "Homework is worth 20% of your grade. Late homework loses 10% per day.",
        "CS 1331 meets Tuesdays and Thursdays in Klaus 1443.",
        "Lab 2 covers recursion. Lab 3 covers sorting.",
        "Office hours are on Wednesdays.",
    ]

    @Test func findsExactCourseCodesEitherWayTheyAreWritten() {
        let index = LexicalIndex(documents: documents)
        #expect(index.rank("cs1331").first?.index == 1)
        #expect(index.rank("CS 1331 schedule").first?.index == 1)
    }

    @Test func ranksTheDocumentWithMoreMatchingTermsFirst() {
        let index = LexicalIndex(documents: documents)
        #expect(index.rank("late homework policy").first?.index == 0)
    }

    @Test func numbersDistinguishOtherwiseSimilarItems() {
        let index = LexicalIndex(documents: ["Lab 2 is due Friday.", "Lab 3 is due Monday."])
        #expect(index.rank("lab 3").first?.index == 1)
    }

    @Test func returnsNothingForUnrelatedOrStopWordOnlyQueries() {
        let index = LexicalIndex(documents: documents)
        #expect(index.rank("photosynthesis").isEmpty)
        #expect(index.rank("what is the").isEmpty)
        #expect(LexicalIndex(documents: []).rank("homework").isEmpty)
    }

    @Test func respectsTheFilter() {
        let index = LexicalIndex(documents: documents)
        #expect(index.rank("lab") { $0 != 2 }.isEmpty)
    }
}

struct RankFusionTests {
    @Test func rewardsItemsRankedWellByBothLists() {
        let fused = RankFusion.fuse([["a", "b", "c"], ["c", "b", "d"]]).map(\.key)
        #expect(fused.first == "b" || fused.first == "c")
        #expect(Set(fused) == ["a", "b", "c", "d"])
        #expect(fused.last == "d" || fused.last == "a")
    }

    @Test func aTopHitInOneListBeatsAMiddlingHitInOne() {
        let fused = RankFusion.fuse([["exact"], ["x", "y", "z", "exact"]]).map(\.key)
        #expect(fused.first == "exact")
    }

    @Test func tiesKeepFirstSeenOrder() {
        #expect(RankFusion.fuse([["a"], ["b"]]).map(\.key) == ["a", "b"])
    }

    @Test func emptyRankingsGiveNothing() {
        #expect(RankFusion.fuse([[String](), []]).isEmpty)
    }
}

struct PassageRetrieverTests {
    @Test func ranksTheGradingParagraphFirstWithoutAModel() async {
        let syllabus = [
            "Welcome to CS 1332! This course covers data structures.",
            "Grading: Homework 30%, Quizzes 10%, Midterm exams 30%, Final exam 30%.",
            "Academic integrity: all work must be your own.",
        ]

        let ranked = await PassageRetriever.rank(
            syllabus,
            for: "assignment groups categories weights percent grade breakdown homework exams quizzes",
            limit: 2,
            embedder: nil
        )
        #expect(ranked.first == 1)
        #expect(ranked.count == 2)
    }

    @Test func fallsBackToDocumentOrderWhenNothingMatches() async {
        let ranked = await PassageRetriever.rank(["alpha", "beta", "gamma"], for: "zzz", limit: 2, embedder: nil)
        #expect(ranked == [0, 1])
    }
}

@Suite(.serialized)
struct SemanticIndexerLexicalSearchTests {
    private func indexer(with rows: [(sourceID: String, courseID: String, text: String)]) throws -> SemanticIndexer {
        let container = try ModelContainer.makeAgentContainer(inMemory: true)
        let context = ModelContext(container)
        let version = ChunkEmbedder.ModelVersion(identifier: "test", revision: 1)

        for (ordinal, row) in rows.enumerated() {
            let chunk = TextChunk(sourceID: row.sourceID, ordinal: ordinal, headingPath: [], text: row.text)
            context.insert(IndexedChunk(chunk: chunk, courseID: row.courseID, sourceRevision: nil, vectorData: Data(), vectorCount: 0, modelVersion: version))
        }
        try context.save()
        return SemanticIndexer(modelContainer: container)
    }

    @Test func findsStoredChunksByKeywordAndScopesByCourse() async throws {
        let indexer = try indexer(with: [
            ("page:1", "100", "The late policy: 10% off per day, up to three days."),
            ("page:2", "200", "Late submissions are not accepted in this course."),
            ("assignment:3", "100", "PS5 covers dynamic programming."),
        ])

        let all = try await indexer.lexicalSearch("late policy", limit: 5)
        #expect(all.map(\.sourceID) == ["page:1", "page:2"])

        let scoped = try await indexer.lexicalSearch("late", courseID: "200", limit: 5)
        #expect(scoped.map(\.sourceID) == ["page:2"])

        let code = try await indexer.lexicalSearch("ps5", limit: 5)
        #expect(code.map(\.sourceID) == ["assignment:3"])
    }

    @Test func hybridSearchStillFindsKeywordMatchesWithoutVectors() async throws {
        let indexer = try indexer(with: [
            ("page:1", "100", "Office hours: Wednesdays 2–4 PM in CCB 345."),
            ("page:2", "100", "Exam 1 is on October 3."),
        ])

        let results = try await indexer.hybridSearch("office hours", limit: 3)
        #expect(results.first?.sourceID == "page:1")
    }
}
