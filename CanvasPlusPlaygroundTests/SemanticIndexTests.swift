//
//  SemanticIndexTests.swift
//  CanvasPlusPlaygroundTests
//
//  Created by Kareem Alaiwat on 10/19/26.
//

import CoreText
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
    @Test func rebuildsAStoreItCannotOpen() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "agent-\(UUID().uuidString).store")
        defer { try? ModelContainer.eraseAgentStore(at: url) }
        try Data("not a database".utf8).write(to: url)

        let context = ModelContext(try ModelContainer.makeAgentContainer(url: url))
        let chunk = TextChunk(sourceID: "page:1", ordinal: 0, headingPath: [], text: "Exams are 40%.")
        let (data, count) = IndexedChunk.encode([[1, 0]])
        context.insert(IndexedChunk(chunk: chunk, courseID: nil, sourceRevision: nil, vectorData: data, vectorCount: count, modelVersion: .init(identifier: "test", revision: 1)))
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<IndexedChunk>()) == 1)
    }

    @Test func persistsAndFetchesChunksInMemory() throws {
        let container = try ModelContainer.makeAgentContainer(inMemory: true)
        let context = ModelContext(container)
        let chunk = TextChunk(sourceID: "page:1", ordinal: 0, headingPath: ["Syllabus"], text: "Exams are 40%.")
        let (data, count) = IndexedChunk.encode([[0.6, 0.8]])
        let version = ChunkEmbedder.ModelVersion(identifier: "test", revision: 1)

        context.insert(IndexedChunk(chunk: chunk, courseID: "1", sourceRevision: nil, vectorData: data, vectorCount: count, modelVersion: version))
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

struct FileIndexSourceTests {
    static func temporaryFile(_ name: String, contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString)-\(name)")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func makePDF(pages: [String]) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).pdf")
        var box = CGRect(x: 0, y: 0, width: 612, height: 792)
        let context = try #require(CGContext(url as CFURL, mediaBox: &box, nil))
        let font = CTFontCreateWithName("Helvetica" as CFString, 14, nil)

        for page in pages {
            context.beginPDFPage(nil)
            let text = NSAttributedString(string: page, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font])
            let framesetter = CTFramesetterCreateWithAttributedString(text)
            let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), CGPath(rect: box.insetBy(dx: 72, dy: 72), transform: nil), nil)
            CTFrameDraw(frame, context)
            context.endPDFPage()
        }
        context.closePDF()
        return url
    }

    private func chunks(_ url: URL) -> [TextChunk] {
        IndexSource(sourceID: "file:1", courseID: "42", title: "Handout", content: .file(url)).chunks(using: Chunker())
    }

    @Test func extractsEachPDFPageAsItsOwnBlock() throws {
        let url = try Self.makePDF(pages: ["Exam 1 covers sorting.", "Exam 2 covers graphs."])
        defer { try? FileManager.default.removeItem(at: url) }

        let chunks = chunks(url)
        #expect(chunks.map(\.text) == ["Exam 1 covers sorting.\nExam 2 covers graphs."])
        #expect(chunks.first?.headingPath == ["Handout"])
        #expect(chunks.first?.sourceID == "file:1")
    }

    @Test func extractsTextAndHTMLFiles() throws {
        let text = try Self.temporaryFile("notes.txt", contents: "Bring a calculator.\n\nNo phones.")
        let html = try Self.temporaryFile("page.html", contents: "<h2>Rules</h2><p>No phones.</p>")
        defer { [text, html].forEach { try? FileManager.default.removeItem(at: $0) } }

        #expect(chunks(text).map(\.text) == ["Bring a calculator.\nNo phones."])
        #expect(chunks(html).map(\.headingPath) == [["Handout", "Rules"]])
    }

    @Test func indexesNothingForUnsupportedOrMissingFiles() throws {
        let slides = try Self.temporaryFile("lecture.pptx", contents: "binary")
        defer { try? FileManager.default.removeItem(at: slides) }

        #expect(chunks(slides).isEmpty)
        #expect(chunks(FileManager.default.temporaryDirectory.appending(path: "missing.pdf")).isEmpty)
    }
}

@Suite(.enabled(if: EmbeddingModel.isUsable), .serialized)
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

    // Unsaved duplicate models (e.g. sandbox data inserted before a save) yield the same source twice.
    @Test func indexesASourceListedTwiceInOneBatchOnce() async throws {
        let (indexer, _) = try makeIndexer()

        let report = await indexer.index([Self.page(), Self.page()])

        #expect(report == SemanticIndexer.Report(embedded: 3))
    }

    // Watches the store from a second context while a long run is still going.
    @Test func savesProgressBeforeALongRunFinishes() async throws {
        let container = try ModelContainer.makeAgentContainer(inMemory: true)
        let indexer = SemanticIndexer(modelContainer: container)
        let observer = ModelContext(container)
        let sources = (0..<80).map {
            IndexSource(sourceID: "page:\($0)", courseID: "42", title: nil, html: "<p>Exam \($0) covers chapter \($0 % 9) and is worth \($0 % 30) percent.</p>")!
        }

        let run = Task { await indexer.index(sources) }
        var partialCount: Int?
        while partialCount == nil {
            let count = try observer.fetchCount(FetchDescriptor<IndexedChunk>())
            if count == sources.count { break }
            if count > 0 { partialCount = count }
            try await Task.sleep(for: .milliseconds(5))
        }
        let report = await run.value

        #expect(partialCount != nil, "rows only appeared once the whole run had finished")
        #expect(report.embedded == sources.count)
    }

    @Test func removingASectionDeletesItsRow() async throws {
        let (indexer, context) = try makeIndexer()
        await indexer.index([Self.page()])

        let report = await indexer.index([Self.page(sections: 2)])

        #expect(report.deleted == 1)
        #expect(try context.fetchCount(FetchDescriptor<IndexedChunk>()) == 2)
    }

    // Deleting the file between runs proves the second run never opened it.
    @Test func skipsAnUnchangedRevisionWithoutReadingTheFile() async throws {
        let (indexer, context) = try makeIndexer()
        let url = try FileIndexSourceTests.temporaryFile("notes.txt", contents: "Bring a calculator.\n\nNo phones allowed during exams.")
        let source = { (revision: String) in
            IndexSource(sourceID: "file:1", courseID: "42", title: "Notes", content: .file(url), revision: revision)
        }
        let first = await indexer.index([source("r1")])
        try FileManager.default.removeItem(at: url)

        let unchanged = await indexer.index([source("r1")])
        #expect(unchanged == SemanticIndexer.Report(kept: first.embedded))
        #expect(try context.fetchCount(FetchDescriptor<IndexedChunk>()) == first.embedded)

        let changed = await indexer.index([source("r2")])
        #expect(changed.deleted == first.embedded)
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

struct SemanticSearchRankingTests {
    @Test func ranksByCosineSimilarityBestFirst() {
        let ranked = SemanticIndexer.rank(query: [1, 0], candidates: [[[0, 1]], [[1, 0]], [[1, 1]]], centroid: nil)
        #expect(ranked.map(\.index) == [1, 2, 0])
        #expect(abs(ranked[0].score - 1) < 1e-6)
    }

    @Test func scoresACandidateByItsBestVector() {
        let ranked = SemanticIndexer.rank(query: [1, 0], candidates: [[[0, 1], [1, 0]], [[1, 1]]], centroid: nil)
        #expect(ranked.map(\.index) == [0, 1])
    }

    // Raw cosine favors [20, 2] (same angle as the query); after removing the shared [10, 0], [10, 1.5] matches best.
    @Test func centeringRemovesTheSharedDirection() {
        let query: [Float] = [10, 1]
        let candidates: [[[Float]]] = [[[10, -1]], [[10, 1.5]], [[20, 2]]]

        let raw = SemanticIndexer.rank(query: query, candidates: candidates, centroid: nil)
        let centered = SemanticIndexer.rank(query: query, candidates: candidates, centroid: [10, 0])

        #expect(raw.first?.index == 2)
        #expect(centered.first?.index == 1)
    }

    @Test func skipsVectorsOfAnotherDimensionAndIgnoresAMismatchedCentroid() {
        let ranked = SemanticIndexer.rank(query: [1, 0], candidates: [[[1, 0, 0]], [], [[1, 0]]], centroid: [1, 2, 3])
        #expect(ranked.map(\.index) == [2])
    }

    // Reference cosine computed the slow, obvious way; catches layout mistakes in the vDSP path.
    @Test func matrixScoringMatchesPlainCosineSimilarity() {
        var rng = SeededGenerator(seed: 77)
        let random = { (count: Int) in (0..<count).map { _ in Float.random(in: -1...1, using: &rng) } }
        let candidates = (0..<40).map { _ in (0..<Int.random(in: 1...3, using: &rng)).map { _ in random(16) } }
        let centroid = random(16)
        let query = random(16)

        func cosine(_ a: [Float], _ b: [Float]) -> Float {
            let dot = zip(a, b).reduce(0) { $0 + $1.0 * $1.1 }
            return dot / (a.reduce(0) { $0 + $1 * $1 }.squareRoot() * b.reduce(0) { $0 + $1 * $1 }.squareRoot())
        }
        let center = { (v: [Float]) in zip(v, centroid).map(-) }
        let expected = candidates.enumerated()
            .map { index, vectors in (index, vectors.map { cosine(center(query), center($0)) }.max()!) }
            .sorted { $0.1 > $1.1 }

        let ranked = SemanticIndexer.rank(query: query, candidates: candidates, centroid: centroid)

        #expect(ranked.map(\.index) == expected.map(\.0))
        for (actual, reference) in zip(ranked, expected) {
            #expect(abs(actual.score - reference.1) < 1e-5)
        }
    }

    @Test func meanAveragesEqualLengthVectors() {
        #expect(SemanticIndexer.mean([[1, 2], [3, 4], []]) == [2, 3])
        #expect(SemanticIndexer.mean([]) == nil)
    }
}

@Suite(.enabled(if: EmbeddingModel.isUsable), .serialized)
struct SemanticSearchModelTests {
    static let sections: [(name: String, html: String)] = [
        ("exams", "<h2>Exams</h2><p>Exam 1 is on October 3 and Exam 2 is on November 7 in the lecture hall.</p>"),
        ("late", "<h2>Late Policy</h2><p>Late work loses 10% per day and is not accepted after three days.</p>"),
        ("office", "<h2>Office Hours</h2><p>Office hours are Monday and Wednesday from 2 to 4pm in CCB 345.</p>"),
        ("grading", "<h2>Grading</h2><p>Homework is worth 40%, exams 40%, and participation 20%.</p>"),
        ("integrity", "<h2>Academic Integrity</h2><p>Collaboration on homework is allowed but all code you submit must be your own.</p>"),
        ("textbook", "<h2>Materials</h2><p>The required textbook is Introduction to Algorithms by Cormen, available at the library.</p>"),
        ("regrade", "<h2>Regrades</h2><p>Regrade requests must be submitted on Gradescope within one week of grades being released.</p>"),
        ("attendance", "<h2>Attendance</h2><p>Attendance is taken in recitation; more than three absences lowers your grade.</p>"),
    ]

    static let paraphrasedQueries: [(query: String, expected: String)] = [
        ("When is the midterm?", "exams"),
        ("What happens if I submit my homework late?", "late"),
        ("When can I meet with the professor?", "office"),
        ("How much are exams worth?", "grading"),
        ("Can I work with a friend on the homework?", "integrity"),
        ("What book do I need to buy?", "textbook"),
        ("I think my grade is wrong, what do I do?", "regrade"),
        ("Do I have to go to class?", "attendance"),
    ]

    private func indexedSyllabus() async throws -> SemanticIndexer {
        let indexer = SemanticIndexer(modelContainer: try .makeAgentContainer(inMemory: true))
        let sources = Self.sections.map { IndexSource(sourceID: "page:\($0.name)", courseID: "42", title: "Syllabus", html: $0.html)! }
        await indexer.index(sources)
        return indexer
    }

    private func meanReciprocalRank(_ indexer: SemanticIndexer, meanCentered: Bool) async throws -> Double {
        var total = 0.0
        for (query, expected) in Self.paraphrasedQueries {
            let matches = try await indexer.search(query, limit: Self.sections.count, meanCentered: meanCentered)
            let rank = try #require(matches.firstIndex { $0.sourceID == "page:\(expected)" }) + 1
            total += 1 / Double(rank)
        }
        return total / Double(Self.paraphrasedQueries.count)
    }

    @Test func findsAChunkFromItsOwnWording() async throws {
        let indexer = try await indexedSyllabus()
        let matches = try await indexer.search("Regrade requests must be submitted on Gradescope within one week", limit: 3)
        #expect(matches.first?.sourceID == "page:regrade")
        #expect(matches.map(\.score) == matches.map(\.score).sorted(by: >))
    }

    @Test func filtersByCourseAndHonorsTheLimit() async throws {
        let indexer = try await indexedSyllabus()
        await indexer.index([IndexSource(sourceID: "page:other", courseID: "7", title: "Other", html: "<p>Exam 1 is on October 3.</p>")!])

        let inCourse = try await indexer.search("When is Exam 1?", courseID: "7", limit: 5)
        #expect(inCourse.map(\.sourceID) == ["page:other"])
        #expect(try await indexer.search("When is Exam 1?", limit: 2).count == 2)
        #expect(try await indexer.search("When is Exam 1?", limit: 0).isEmpty)
    }

    // Small handwritten set: guards the direction of the centering effect, not absolute quality.
    @Test func meanCenteringDoesNotHurtParaphraseRetrieval() async throws {
        let indexer = try await indexedSyllabus()
        let raw = try await meanReciprocalRank(indexer, meanCentered: false)
        let centered = try await meanReciprocalRank(indexer, meanCentered: true)

        print("SemanticSearch MRR on \(Self.paraphrasedQueries.count) paraphrased queries — raw \(raw), centered \(centered)")
        #expect(centered >= raw)
    }
}

struct IndexSourceDeduplicationTests {
    @Test func keepsTheLastSnapshotOfEachSourceInFirstSeenOrder() {
        let sources = [
            IndexSource(sourceID: "page:1", courseID: nil, title: nil, content: .plainText("old")),
            IndexSource(sourceID: "page:2", courseID: nil, title: nil, content: .plainText("b")),
            IndexSource(sourceID: "page:1", courseID: nil, title: nil, content: .plainText("new")),
        ]
        let unique = SemanticIndexer.uniqued(sources)

        #expect(unique.map(\.sourceID) == ["page:1", "page:2"])
        #expect(unique.first?.content == .plainText("new"))
    }
}

struct IndexStorageTests {
    @Test func excludesOnlySourcesOfRetiredCourses() {
        let sources = [
            IndexSource(sourceID: "page:1", courseID: "old", title: nil, content: .plainText("a")),
            IndexSource(sourceID: "page:2", courseID: "current", title: nil, content: .plainText("b")),
            IndexSource(sourceID: "file:3", courseID: nil, title: nil, content: .plainText("c")),
        ]
        let kept = SemanticIndexer.excludingRetired(sources, retiredCourseIDs: ["old"])
        #expect(kept.map(\.sourceID) == ["page:2", "file:3"])
    }

    @Test func reportsChunksAndBytesPerCourse() async throws {
        let container = try ModelContainer.makeAgentContainer(inMemory: true)
        let context = ModelContext(container)
        let version = ChunkEmbedder.ModelVersion(identifier: "test", revision: 1)
        let (data, count) = IndexedChunk.encode([[Float](repeating: 0.5, count: 512)])
        for (ordinal, courseID) in ["42", "42", "7", nil].enumerated() {
            let chunk = TextChunk(sourceID: "page:\(ordinal)", ordinal: 0, headingPath: [], text: "abcd")
            context.insert(IndexedChunk(chunk: chunk, courseID: courseID, sourceRevision: nil, vectorData: data, vectorCount: count, modelVersion: version))
        }
        try context.save()

        let report = try await SemanticIndexer(modelContainer: container).storageReport()

        #expect(report.byCourse["42"] == .init(chunks: 2, vectorBytes: 4096, textBytes: 8))
        #expect(report.byCourse["7"]?.chunks == 1)
        #expect(report.byCourse[nil]?.chunks == 1)
        #expect(report.total.chunks == 4)
        #expect(report.storeFileBytes == nil)
    }

    // Measures what one realistic row costs on disk; multiply by a real account's row count for total size.
    @Test func measuresOnDiskBytesPerRow() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "agent-size-\(UUID().uuidString).store")
        defer { try? ModelContainer.eraseAgentStore(at: url) }
        let container = try ModelContainer.makeAgentContainer(url: url)
        let context = ModelContext(container)
        let version = ChunkEmbedder.ModelVersion(identifier: "5C45D94E-BAB4-4927-94B6-8B5745C46289", revision: 1)
        var rng = SeededGenerator(seed: 3)
        let text = String(repeating: "Late work loses 10% per day and is not accepted after three days. ", count: 9)

        let rows = 500
        for index in 0..<rows {
            let vector = (0..<512).map { _ in Float.random(in: -0.1...0.1, using: &rng) }
            let (data, count) = IndexedChunk.encode([vector])
            let chunk = TextChunk(sourceID: "page:\(index / 3)", ordinal: index % 3, headingPath: ["CS 2340 Syllabus", "Late Policy"], text: text)
            context.insert(IndexedChunk(chunk: chunk, courseID: "42", sourceRevision: "1729300000-48211", vectorData: data, vectorCount: count, modelVersion: version))
        }
        try context.save()

        let report = try await SemanticIndexer(modelContainer: container).storageReport()
        let bytesOnDisk = try #require(report.storeFileBytes)
        let bytesPerRow = Double(bytesOnDisk) / Double(rows)
        print("Agent store: \(rows) rows, \(bytesOnDisk) bytes on disk, \(Int(bytesPerRow)) bytes per row; \(report)")

        // Each row carries a 2,048-byte vector, so anything below that means vectors aren't being stored.
        #expect(bytesPerRow > 2_048)
        #expect(bytesPerRow < 8_192)
    }
}
