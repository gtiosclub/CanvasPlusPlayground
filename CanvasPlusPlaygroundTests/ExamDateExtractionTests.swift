//
//  ExamDateExtractionTests.swift
//  CanvasPlusPlaygroundTests
//

import Foundation
import FoundationModels
import Testing
@testable import CanvasPlusPlayground

private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/New_York")!
    return calendar
}()

private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

/// Fall 2026: Aug 17 – Dec 11.
private let fall = DateInterval(start: date(2026, 8, 17), end: date(2026, 12, 11))
/// Spring 2027: Jan 11 – May 7, so "Jan 20" and "Dec 15" need different years.
private let spring = DateInterval(start: date(2027, 1, 11), end: date(2027, 5, 7))

private let syllabus = """
<h2>Schedule</h2>
<p>Homework is due every Friday.</p>
<p>Midterm 1 is on October 14 at 6:30 PM in Klaus 1443.</p>
<p>Midterm 2: November 18.</p>
<p>The final exam is Thursday, December 10.</p>
<p>Office hours are on Wednesdays.</p>
"""

struct ExamYearResolutionTests {
    @Test func usesTheTermYear() {
        #expect(ExamDateExtractor.resolve(month: 10, day: 14, within: fall, calendar: calendar) == date(2026, 10, 14))
        #expect(ExamDateExtractor.resolve(month: 3, day: 2, within: spring, calendar: calendar) == date(2027, 3, 2))
    }

    @Test func allowsFinalsWeekJustAfterTheTerm() {
        #expect(ExamDateExtractor.resolve(month: 12, day: 15, within: fall, calendar: calendar) == date(2026, 12, 15))
    }

    @Test func rejectsDatesOutsideTheTerm() {
        #expect(ExamDateExtractor.resolve(month: 7, day: 1, within: fall, calendar: calendar) == nil)
        #expect(ExamDateExtractor.resolve(month: 2, day: 30, within: spring, calendar: calendar) == nil)
    }

    @Test func withoutATermPicksTheNextOccurrence() {
        let now = date(2026, 11, 16)
        #expect(ExamDateExtractor.resolve(month: 12, day: 10, within: nil, now: now, calendar: calendar) == date(2026, 12, 10))
        #expect(ExamDateExtractor.resolve(month: 2, day: 3, within: nil, now: now, calendar: calendar) == date(2027, 2, 3))
    }
}

struct ExamDateDetectorTests {
    var text: String { ExamDateExtractor.relevantText(fromHTML: syllabus) }

    @Test func keepsOnlyParagraphsAboutExams() {
        #expect(text.contains("Midterm 1"))
        #expect(text.contains("final exam"))
        #expect(!text.contains("Office hours"))
        #expect(!text.contains("<p>"))
    }

    @Test func findsExamDatesWithoutAModel() throws {
        let found = ExamDateExtractor.detectorCandidates(in: text, term: fall, calendar: calendar)

        let midterm = try #require(found.first { calendar.isDate($0.date, inSameDayAs: date(2026, 10, 14)) })
        #expect(midterm.kind == .midterm)
        #expect(midterm.title.hasPrefix("Midterm 1"))
        #expect(midterm.hasTime)
        #expect(calendar.component(.hour, from: midterm.date) == 18)

        #expect(found.contains { calendar.isDate($0.date, inSameDayAs: date(2026, 11, 18)) && !$0.hasTime })
        #expect(found.contains { $0.kind == .final && calendar.isDate($0.date, inSameDayAs: date(2026, 12, 10)) })
        // "Homework is due every Friday" has no exam word and isn't a date.
        #expect(found.allSatisfy { !$0.sourceSnippet.contains("Homework") })
    }

    @Test func detectorUsesTheTermYearNotThisYear() {
        let found = ExamDateExtractor.detectorCandidates(in: "Exam 1 is on January 20.", term: spring, calendar: calendar)
        #expect(found.first.map { calendar.component(.year, from: $0.date) } == 2027)
    }
}

struct ExamDateChecksTests {
    @Test func quotesMustBeInTheSyllabus() {
        let text = ExamDateExtractor.relevantText(fromHTML: syllabus)
        #expect(ExamDateExtractor.contains(text, quote: "Midterm 2: November 18."))
        #expect(ExamDateExtractor.contains(text, quote: "midterm 2 november 18"))
        #expect(!ExamDateExtractor.contains(text, quote: "Midterm 3 is on December 1."))
        #expect(!ExamDateExtractor.contains(text, quote: "Exam"))  // too short to prove anything
    }

    @Test func skipsWhatTheCalendarAlreadyHasAndRepeats() {
        let candidates = [
            ExamDateCandidate(title: "Midterm 1", kind: .midterm, date: date(2026, 10, 14, 18, 30), hasTime: true, sourceSnippet: "a"),
            ExamDateCandidate(title: "Midterm 1", kind: .midterm, date: date(2026, 10, 14), hasTime: false, sourceSnippet: "b"),
            ExamDateCandidate(title: "Midterm 2", kind: .midterm, date: date(2026, 11, 18), hasTime: false, sourceSnippet: "c"),
            ExamDateCandidate(title: "Final Exam", kind: .final, date: date(2026, 12, 10), hasTime: false, sourceSnippet: "d"),
        ]
        let existing = [(title: "CS 1331 Midterm 2", date: date(2026, 11, 18, 19))]

        let kept = ExamDateExtractor.removingDuplicates(candidates, existing: existing, calendar: calendar)
        #expect(kept.map(\.title) == ["Midterm 1", "Final Exam"])
    }

    @Test func kindsAreInferredFromWords() {
        #expect(ExamDateCandidate.Kind.infer(from: "Final Exam") == .final)
        #expect(ExamDateCandidate.Kind.infer(from: "Test 2") == .midterm)
        #expect(ExamDateCandidate.Kind.infer(from: "Pop quiz") == .quiz)
        #expect(ExamDateCandidate.Kind.infer(from: "Project milestone 1") == .project)
    }
}

@MainActor
struct ExamDateModelTests {
    @Test func modelDatesNeedARealQuoteAndATermYear() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let text = ExamDateExtractor.relevantText(fromHTML: syllabus)
        let reply = """
        {"events": [
          {"title": "Midterm 1", "kind": "midterm", "month": 10, "day": 14, "startTime": "18:30", "location": "Klaus 1443", "quote": "Midterm 1 is on October 14 at 6:30 PM in Klaus 1443."},
          {"title": "Midterm 3", "kind": "midterm", "month": 12, "day": 1, "quote": "Midterm 3 is on December 1."},
          {"title": "Summer quiz", "kind": "quiz", "month": 7, "day": 1, "quote": "Midterm 2: November 18."}
        ]}
        """
        let provider = ScriptedModelProvider(steps: [.respond(json: reply)])

        let found = try await ExamDateExtractor.modelCandidates(in: text, term: fall, provider: provider, calendar: calendar)

        #expect(found.count == 1)
        let midterm = try #require(found.first)
        #expect(midterm.date == date(2026, 10, 14, 18, 30))
        #expect(midterm.hasTime)
        #expect(midterm.location == "Klaus 1443")
    }
}

struct ExamDateScanStoreTests {
    @Test @MainActor func roundTrips() {
        let store = ExamDateScanStore(directory: URL.temporaryDirectory.appending(path: "scans-\(UUID())"))
        let scan = ExamDateScanner.Scan(
            courseID: "42",
            syllabusHash: "abc",
            scannedAt: date(2026, 9, 1),
            usedModel: false,
            candidates: [ExamDateCandidate(title: "Final", kind: .final, date: date(2026, 12, 10), hasTime: false, sourceSnippet: "Final on Dec 10")],
            handledIDs: []
        )
        store.save(scan)
        #expect(store.load(courseID: "42") == scan)
        #expect(store.load(courseID: "nope") == nil)
    }
}
