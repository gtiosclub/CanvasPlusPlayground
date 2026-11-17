//
//  IndexBenchmarkTests.swift
//  CanvasPlusPlaygroundTests
//
//  Created by Kareem Alaiwat on 10/19/26.
//

import Foundation
import SwiftData
import Testing
@testable import CanvasPlusPlayground

/// Sizes and times a synthetic full semester through the real pipeline (chunker, PDFKit,
/// NLContextualEmbedding, on-disk agent store). An estimate, not a measurement of a real
/// account: content volume follows `Profile`, which is an assumption to revise with real data.
///
/// Opt-in because it embeds thousands of chunks:
/// `TEST_RUNNER_RUN_INDEX_BENCHMARK=1 xcodebuild test -destination 'platform=macOS' -parallel-testing-enabled NO -only-testing:CanvasPlusPlaygroundTests/IndexBenchmarkTests …`
/// Keep parallel testing off: otherwise two runner processes execute this suite at once and the timings double.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["RUN_INDEX_BENCHMARK"] == "1" && EmbeddingModel.isUsable), .serialized)
struct IndexBenchmarkTests {
    struct Profile {
        var courses = 5
        var syllabusSections = 10, wordsPerSyllabusSection = 150
        var pages = 25, wordsPerPage = 400
        var assignments = 30, wordsPerAssignment = 250
        var announcements = 40, wordsPerAnnouncement = 120
        var discussions = 10, wordsPerDiscussion = 150
        var quizzes = 10, wordsPerQuiz = 60
        var downloadedPDFs = 15, pagesPerPDF = 12, wordsPerPDFPage = 300
    }

    private static let subjects = [
        "The midterm", "Homework 3", "Lab 5", "The final project", "Recitation", "Office hours", "Quiz 2",
        "This week's reading", "The group presentation", "Project 2", "The regrade policy", "Attendance",
        "The lecture on graph search", "Problem set 4", "The capstone proposal", "Peer review",
    ]
    private static let predicates = [
        "covers dynamic programming, greedy algorithms, and amortized analysis",
        "is due Friday at 11:59 PM on Gradescope, with a 10% penalty per late day",
        "will be held in Klaus 1443 from 9:30 to 10:45 AM",
        "counts for 15% of the final grade and cannot be dropped",
        "requires a two-page write-up in PDF format with citations",
        "must be completed individually, although discussing ideas is encouraged",
        "has been moved to the following Tuesday because of the career fair",
        "builds on chapters 4.1 through 4.3 of the Sipser textbook",
        "should include unit tests that cover every edge case described in the handout",
        "is optional but recommended for anyone struggling with recursion",
        "uses the rubric posted under Files, so review it before you start",
        "will be recorded and posted to Media Gallery within 24 hours",
    ]

    private static func text(words: Int, using rng: inout SeededGenerator) -> String {
        var sentences: [String] = []
        var count = 0
        while count < words {
            let sentence = "\(subjects.randomElement(using: &rng)!) \(predicates.randomElement(using: &rng)!) (section \(Int.random(in: 1...9, using: &rng)))."
            sentences.append(sentence)
            count += sentence.split(separator: " ").count
        }
        return sentences.joined(separator: " ")
    }

    private static func html(sections: Int, wordsPerSection: Int, using rng: inout SeededGenerator) -> String {
        (1...sections).map { "<h2>Section \($0)</h2><p>\(text(words: wordsPerSection, using: &rng))</p>" }.joined()
    }

    private static func sources(_ profile: Profile, pdfDirectory: URL) throws -> [IndexSource] {
        var rng = SeededGenerator(seed: 2026)
        var sources: [IndexSource] = []

        for course in 1...profile.courses {
            let courseID = "bench-\(course)"
            func add(_ kind: String, _ count: Int, title: String, html: (inout SeededGenerator) -> String) {
                for index in 1...count {
                    sources.append(IndexSource(sourceID: "\(kind):\(course)-\(index)", courseID: courseID, title: "\(title) \(index)", html: html(&rng))!)
                }
            }

            add("syllabus", 1, title: "Syllabus") { html(sections: profile.syllabusSections, wordsPerSection: profile.wordsPerSyllabusSection, using: &$0) }
            add("page", profile.pages, title: "Page") { html(sections: 3, wordsPerSection: profile.wordsPerPage / 3, using: &$0) }
            add("assignment", profile.assignments, title: "Assignment") { "<p>\(text(words: profile.wordsPerAssignment, using: &$0))</p>" }
            add("announcement", profile.announcements, title: "Announcement") { "<p>\(text(words: profile.wordsPerAnnouncement, using: &$0))</p>" }
            add("discussion", profile.discussions, title: "Discussion") { "<p>\(text(words: profile.wordsPerDiscussion, using: &$0))</p>" }
            add("quiz", profile.quizzes, title: "Quiz") { "<p>\(text(words: profile.wordsPerQuiz, using: &$0))</p>" }

            for index in 1...profile.downloadedPDFs {
                let pages = (1...profile.pagesPerPDF).map { _ in text(words: profile.wordsPerPDFPage, using: &rng) }
                let generated = try FileIndexSourceTests.makePDF(pages: pages)
                let url = pdfDirectory.appending(path: "\(course)-\(index).pdf")
                try FileManager.default.moveItem(at: generated, to: url)
                sources.append(IndexSource(sourceID: "file:\(course)-\(index)", courseID: courseID, title: "Lecture \(index)", content: .file(url), revision: "1"))
            }
        }
        return sources
    }

    @Test func fullSemesterLoad() async throws {
        let profile = Profile()
        let directory = FileManager.default.temporaryDirectory.appending(path: "index-benchmark-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let clock = ContinuousClock()
        let sources = try Self.sources(profile, pdfDirectory: directory)
        let indexer = SemanticIndexer(modelContainer: try .makeAgentContainer(url: directory.appending(path: "agent.store")))

        // An empty index makes this a pure model load.
        let modelLoad = try await clock.measure { _ = try await indexer.search("warm up") }
        var cold = SemanticIndexer.Report()
        let coldTime = await clock.measure { cold = await indexer.index(sources) }
        var warm = SemanticIndexer.Report()
        let warmTime = await clock.measure { warm = await indexer.index(sources) }
        let storage = try await indexer.storageReport()

        // The first query after a write also builds the search cache; later ones only embed the query and multiply.
        let firstSearch = try await clock.measure { _ = try await indexer.search("When is the midterm?", limit: 5) }
        let queries = ["What is the late penalty?", "Where is recitation held?", "Can I work with a partner?", "Which chapters should I read?"]
        let searchTime = try await clock.measure {
            for query in queries { _ = try await indexer.search(query, limit: 5) }
        } / queries.count

        let chunks = storage.total.chunks
        let disk = try #require(storage.storeFileBytes)
        print("""
            BENCHMARK profile: \(profile.courses) courses × (syllabus, \(profile.pages) pages, \(profile.assignments) assignments, \
            \(profile.announcements) announcements, \(profile.discussions) discussions, \(profile.quizzes) quizzes, \
            \(profile.downloadedPDFs) PDFs × \(profile.pagesPerPDF) pages) = \(sources.count) sources
            BENCHMARK model load \(modelLoad)
            BENCHMARK cold backfill \(coldTime) — \(cold) — \(String(format: "%.1f", coldTime.milliseconds / Double(max(cold.embedded, 1)))) ms per embedded chunk
            BENCHMARK warm backfill \(warmTime) — \(warm)
            BENCHMARK storage \(chunks) chunks, \(String(format: "%.1f", Double(disk) / 1_048_576)) MB on disk, \(disk / max(chunks, 1)) bytes per chunk
            BENCHMARK per course \(String(format: "%.0f", Double(chunks) / Double(profile.courses))) chunks, \(String(format: "%.1f", Double(disk) / Double(profile.courses) / 1_048_576)) MB
            BENCHMARK search first query \(firstSearch) (builds cache), then \(searchTime) per query over \(chunks) chunks
            """)

        #expect(cold.embedded == chunks)
        #expect(warm.embedded == 0)
        #expect(warm.kept == chunks)
    }
}

private extension Duration {
    var milliseconds: Double {
        Double(components.seconds) * 1_000 + Double(components.attoseconds) / 1e15
    }
}
