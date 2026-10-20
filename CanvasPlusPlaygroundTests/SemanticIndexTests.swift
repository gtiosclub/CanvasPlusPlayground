//
//  SemanticIndexTests.swift
//  CanvasPlusPlaygroundTests
//
//  Created by Kareem Alaiwat on 10/19/26.
//

import Foundation
import NaturalLanguage
import SwiftData
import Testing
@testable import CanvasPlusPlayground

struct IndexedChunkVectorCodingTests {
    @Test func roundTripsVectors() {
        let vectors: [[Float]] = [[0.25, -1, 3.5], [0, 0.125, -7]]
        let (data, count) = IndexedChunk.encode(vectors)

        #expect(count == 2)
        #expect(data.count == 6 * MemoryLayout<Float>.stride)
        #expect(IndexedChunk.decode(data, count: count) == vectors)
    }

    @Test func dropsEmptyVectors() {
        let (data, count) = IndexedChunk.encode([[], [1, 2], []])
        #expect(count == 1)
        #expect(IndexedChunk.decode(data, count: count) == [[1, 2]])
    }

    @Test(arguments: [(Data(), 0), (Data(), 1), (Data(count: 12), 0), (Data(count: 12), 2)])
    func decodesMalformedInputAsEmpty(data: Data, count: Int) {
        #expect(IndexedChunk.decode(data, count: count).isEmpty)
    }
}

struct IndexSourceTests {
    @Test(arguments: [nil, "", "  \n\t "] as [String?])
    func hasNothingToIndexWithoutHTML(html: String?) {
        #expect(IndexSource(sourceID: "page:1", courseID: "1", title: "T", html: html) == nil)
    }

    @Test func chunksWithTheTitleAsOutermostHeading() throws {
        let source = try #require(IndexSource(sourceID: "page:1", courseID: "1", title: "Syllabus", html: "<h2>Grading</h2><p>Exams are 40%.</p>"))
        let chunks = source.chunks(using: Chunker())

        #expect(chunks.map(\.headingPath) == [["Syllabus", "Grading"]])
        #expect(chunks.allSatisfy { $0.sourceID == "page:1" })
    }
}

struct AgentStoreTests {
    @Test func persistsAndFetchesChunksInMemory() throws {
        let container = try ModelContainer.makeAgentContainer(inMemory: true)
        let context = ModelContext(container)
        let chunk = TextChunk(sourceID: "page:1", ordinal: 0, headingPath: ["Syllabus"], text: "Exams are 40%.")
        let (data, count) = IndexedChunk.encode([[0.6, 0.8]])
        let version = ChunkEmbedder.ModelVersion(identifier: "test", revision: 1)

        context.insert(IndexedChunk(chunk: chunk, courseID: "1", vectorData: data, vectorCount: count, modelVersion: version))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<IndexedChunk>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.vectors == [[0.6, 0.8]])
        #expect(fetched.first?.contentHash == chunk.contentHash)
        #expect(fetched.first?.isEmbedded(by: version) == true)
        #expect(fetched.first?.isEmbedded(by: .init(identifier: "test", revision: 2)) == false)
    }
}

struct SemanticIndexerPlanTests {
    @Test func embedsEverythingWhenNothingIsStored() {
        #expect(SemanticIndexer.plan(existingHashes: [:], incomingHashes: ["a", "b"]) == [.embed, .embed])
    }

    @Test func keepsChunksThatAreUnchangedInPlace() {
        #expect(SemanticIndexer.plan(existingHashes: [0: "a", 1: "b"], incomingHashes: ["a", "b"]) == [.keep, .keep])
    }

    @Test func embedsOnlyTheChangedChunk() {
        #expect(SemanticIndexer.plan(existingHashes: [0: "a", 1: "b", 2: "c"], incomingHashes: ["a", "x", "c"]) == [.keep, .embed, .keep])
    }

    @Test func handlesNoIncomingChunks() {
        #expect(SemanticIndexer.plan(existingHashes: [0: "a"], incomingHashes: []).isEmpty)
    }

    @Test func reusesChunksShiftedByAnInsertionAbove() {
        #expect(SemanticIndexer.plan(existingHashes: [0: "a", 1: "b"], incomingHashes: ["new", "a", "b"])
            == [.embed, .reuse(fromOrdinal: 0), .reuse(fromOrdinal: 1)])
    }

    @Test func reusesChunksShiftedByADeletionAbove() {
        #expect(SemanticIndexer.plan(existingHashes: [0: "a", 1: "b", 2: "c"], incomingHashes: ["b", "c"])
            == [.reuse(fromOrdinal: 1), .reuse(fromOrdinal: 2)])
    }

    @Test func prefersKeepingInPlaceOverReusingElsewhere() {
        #expect(SemanticIndexer.plan(existingHashes: [0: "dup", 1: "dup"], incomingHashes: ["x", "dup"])
            == [.embed, .keep])
    }

    @Test func letsDuplicateTextReuseTheSameStoredVectors() {
        #expect(SemanticIndexer.plan(existingHashes: [0: "tbd"], incomingHashes: ["x", "tbd", "tbd"])
            == [.embed, .reuse(fromOrdinal: 0), .reuse(fromOrdinal: 0)])
    }
}

@Suite(.enabled(if: NLContextualEmbedding(language: .english)?.hasAvailableAssets ?? false), .serialized)
struct SemanticIndexerModelTests {
    static func pageHTML(late: String = "Late work loses 10% per day.", sections: Int = 3) -> String {
        let bodies = [
            "<h2>Exams</h2><p>Exam 1 is on October 3 and Exam 2 is on November 7.</p>",
            "<h2>Late Policy</h2><p>\(late)</p>",
            "<h2>Office Hours</h2><p>Office hours are Monday and Wednesday from 2 to 4pm.</p>",
        ]
        return bodies.prefix(sections).joined()
    }

    static func page(late: String = "Late work loses 10% per day.", sections: Int = 3) -> IndexSource {
        IndexSource(sourceID: "page:1", courseID: "42", title: "Syllabus", html: pageHTML(late: late, sections: sections))!
    }

    private func makeIndexer() throws -> (SemanticIndexer, ModelContext) {
        let container = try ModelContainer.makeAgentContainer(inMemory: true)
        return (SemanticIndexer(modelContainer: container), ModelContext(container))
    }

    @Test func indexesEveryChunkOfANewSource() async throws {
        let (indexer, context) = try makeIndexer()

        let report = await indexer.index([Self.page()])

        let rows = try context.fetch(FetchDescriptor<IndexedChunk>(sortBy: [SortDescriptor(\.ordinal)]))
        #expect(report.embedded == 3)
        #expect(rows.map(\.ordinal) == [0, 1, 2])
        #expect(rows.allSatisfy { $0.courseID == "42" && $0.vectorCount >= 1 })
    }

    @Test func reindexingUnchangedContentEmbedsNothing() async throws {
        let (indexer, _) = try makeIndexer()
        await indexer.index([Self.page()])

        let report = await indexer.index([Self.page()])

        #expect(report.embedded == 0)
        #expect(report.kept == 3)
    }

    @Test func reindexingAnEditEmbedsOnlyTheChangedChunk() async throws {
        let (indexer, context) = try makeIndexer()
        await indexer.index([Self.page()])

        let report = await indexer.index([Self.page(late: "Late work is not accepted.")])

        #expect(report.embedded == 1)
        let late = try context.fetch(FetchDescriptor<IndexedChunk>()).first { $0.ordinal == 1 }
        #expect(late?.text == "Late work is not accepted.")
    }

    @Test func insertingASectionAtTheTopReusesTheShiftedVectors() async throws {
        let (indexer, context) = try makeIndexer()
        await indexer.index([Self.page()])
        let before = try context.fetch(FetchDescriptor<IndexedChunk>()).reduce(into: [String: Data]()) { $0[$1.text] = $1.vectorData }

        let html = "<h2>Welcome</h2><p>Welcome to CS 2340.</p>" + Self.pageHTML()
        let report = await indexer.index([IndexSource(sourceID: "page:1", courseID: "42", title: "Syllabus", html: html)!])

        #expect(report.embedded == 1)
        #expect(report.reused == 3)
        let after = try context.fetch(FetchDescriptor<IndexedChunk>(sortBy: [SortDescriptor(\.ordinal)]))
        #expect(after.map(\.ordinal) == [0, 1, 2, 3])
        for row in after.dropFirst() {
            #expect(row.vectorData == before[row.text], "ordinal \(row.ordinal) should carry its old vectors")
        }
    }

    @Test func removingASectionDeletesItsRow() async throws {
        let (indexer, context) = try makeIndexer()
        await indexer.index([Self.page()])

        let report = await indexer.index([Self.page(sections: 2)])

        #expect(report.deleted == 1)
        #expect(try context.fetchCount(FetchDescriptor<IndexedChunk>()) == 2)
    }

    @Test func pruneDeletesSourcesThatNoLongerExist() async throws {
        let (indexer, context) = try makeIndexer()
        let other = IndexSource(sourceID: "page:2", courseID: "42", title: "Other", html: "<p>Bring a calculator.</p>")!
        await indexer.index([Self.page(), other])

        try await indexer.prune(keeping: ["page:2"])

        let remaining = try context.fetch(FetchDescriptor<IndexedChunk>())
        #expect(remaining.map(\.sourceID) == ["page:2"])
    }
}
