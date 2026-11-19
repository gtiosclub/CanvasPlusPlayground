//
//  CourseContractTests.swift
//  CanvasPlusPlaygroundTests
//

import Foundation
import FoundationModels
import Testing
@testable import CanvasPlusPlayground

private let syllabus = """
<h2>Grading</h2>
<ul>
<li>Homework: 20%</li>
<li>Quizzes (best 8 of 10) 10%</li>
<li>Midterm Exams ..... 40%</li>
<li>Final Exam - 30%</li>
</ul>
<p>The lowest two quiz grades will be dropped.</p>
<p>Late submissions lose 10% per day and are not accepted after 3 days.</p>
<p>Attendance is not required but strongly encouraged.</p>
<p>Office hours: Tuesdays 2-4 PM in CCB 345 (Prof. Lee).</p>
<p>Midterm 1 is on October 14.</p>
"""

private let calendar = Calendar(identifier: .gregorian)

private func date(_ month: Int, _ day: Int) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: month, day: day))!
}

private func contract(_ extracted: CourseContractExtractor.Extracted, exams: [ExamDateCandidate] = []) -> CourseContract {
    CourseContract(
        courseID: "1",
        syllabusHash: "h",
        extractedAt: Date(timeIntervalSince1970: 1_790_000_000),
        usedModel: false,
        weights: extracted.weights,
        examDates: exams.map { .init($0, excerpt: $0.sourceSnippet) },
        latePolicy: extracted.latePolicy,
        dropRules: extracted.dropRules,
        attendance: extracted.attendance,
        officeHours: extracted.officeHours
    )
}

struct CourseContractPatternTests {
    var extracted: CourseContractExtractor.Extracted {
        CourseContractExtractor.patternFields(in: CourseContractExtractor.plainText(fromHTML: syllabus))
    }

    @Test func findsEveryWeightLine() {
        let weights = extracted.weights.map(\.value)
        #expect(weights.map(\.name) == ["Homework", "Quizzes", "Midterm Exams", "Final Exam"])
        #expect(weights.map(\.percent) == [20, 10, 40, 30])
    }

    @Test func aLatePenaltyIsNotAGradeCategory() {
        #expect(!extracted.weights.contains { $0.value.name.lowercased().contains("late") })
        #expect(CourseContractExtractor.weight(in: "Late submissions lose 10% per day") == nil)
    }

    @Test func findsPolicies() throws {
        #expect(extracted.dropRules.map(\.value) == [.init(group: "quiz", dropLowest: 2)])
        #expect(try #require(extracted.latePolicy).value.contains("10% per day"))
        #expect(try #require(extracted.attendance).value.contains("not required"))
        #expect(extracted.officeHours.first?.value.contains("CCB 345") == true)
    }

    @Test(arguments: [
        ("Drop the lowest homework score.", CourseContract.DropRule(group: "homework", dropLowest: 1)),
        ("Your lowest 3 lab grades are dropped.", .init(group: "lab", dropLowest: 3)),
    ])
    func parsesDropRules(_ line: String, expected: CourseContract.DropRule) {
        #expect(CourseContractExtractor.dropRule(in: line) == expected)
    }
}

struct CourseContractVerifierTests {
    let groups: [CourseContractVerifier.CanvasGroup] = [
        .init(id: "g1", name: "Homework", weight: 20, dropLowest: nil),
        .init(id: "g2", name: "Quizzes", weight: 15, dropLowest: 2),
        .init(id: "g3", name: "Exams", weight: 40, dropLowest: nil),
        .init(id: "g4", name: "Final", weight: 25, dropLowest: nil),
    ]

    var verified: CourseContract {
        let extracted = CourseContractExtractor.patternFields(in: CourseContractExtractor.plainText(fromHTML: syllabus))
        let exams = [
            ExamDateCandidate(title: "Midterm 1", kind: .midterm, date: date(10, 14), hasTime: false, sourceSnippet: "Midterm 1 is on October 14."),
            ExamDateCandidate(title: "Midterm 2", kind: .midterm, date: date(11, 18), hasTime: false, sourceSnippet: "Midterm 2: November 18."),
        ]
        return CourseContractVerifier.verify(
            contract(extracted, exams: exams),
            groups: groups,
            calendarEvents: [(title: "CS 1331 Midterm 1", date: date(10, 14))],
            calendar: calendar
        )
    }

    @Test func checksTheTotal() {
        #expect(verified.notes.contains { $0.status == .confirmed && $0.text.contains("100%") })

        var off = verified
        off.weights.removeLast()
        let reverified = CourseContractVerifier.verify(off, groups: groups, calendarEvents: [], calendar: calendar)
        #expect(reverified.notes.contains { $0.status == .conflict && $0.text.contains("70%") })
    }

    @Test func matchesWeightsToGroupsByName() {
        let byName = Dictionary(uniqueKeysWithValues: verified.weights.map { ($0.value.name, $0) })
        #expect(byName["Homework"]?.status == .confirmed)
        #expect(byName["Homework"]?.value.groupID == "g1")
        #expect(byName["Quizzes"]?.status == .conflict)       // syllabus 10%, Canvas 15%
        #expect(byName["Quizzes"]?.detail?.contains("15%") == true)
        #expect(byName["Midterm Exams"]?.status == .confirmed) // "Exams" group
        #expect(byName["Final Exam"]?.status == .conflict)     // 30% vs 25% in "Final", not "Exams"
        #expect(byName["Final Exam"]?.value.groupID == "g4")
    }

    @Test func unknownCategoriesAreNotFound() {
        let lone = CourseContractVerifier.verify(
            contract(.init(weights: [.init(.init(name: "Participation", percent: 100), excerpt: "Participation 100%")])),
            groups: groups, calendarEvents: [], calendar: calendar
        )
        #expect(lone.weights.first?.status == .notFound)
    }

    @Test func unweightedCoursesCantConfirmWeights() {
        let unweighted = groups.map { CourseContractVerifier.CanvasGroup(id: $0.id, name: $0.name, weight: 0, dropLowest: $0.dropLowest) }
        let result = CourseContractVerifier.verify(verified, groups: unweighted, calendarEvents: [], calendar: calendar)
        #expect(result.weights.allSatisfy { $0.status == .unverified })
    }

    @Test func checksDropRulesAndExamDates() {
        #expect(verified.dropRules.first?.status == .confirmed)
        #expect(verified.examDates.map(\.status) == [.confirmed, .notFound])
    }

    @Test func roundTripsThroughTheStore() {
        let store = CourseContractStore(directory: URL.temporaryDirectory.appending(path: "contracts-\(UUID())"))
        let contract = verified
        store.save(contract)
        #expect(store.load(courseID: "1") == contract)
    }
}

@MainActor
struct CourseContractModelTests {
    @Test func modelFieldsNeedRealQuotes() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let text = CourseContractExtractor.plainText(fromHTML: syllabus)
        let reply = """
        {"weights": [
            {"name": "Homework", "percent": 20, "quote": "Homework: 20%"},
            {"name": "Labs", "percent": 15, "quote": "Labs are worth 15% of your grade."}
         ],
         "latePolicy": {"summary": "10% off per day, up to 3 days.", "quote": "Late submissions lose 10% per day and are not accepted after 3 days."},
         "dropRules": [{"group": "quiz", "dropLowest": 2, "quote": "The lowest two quiz grades will be dropped."}],
         "attendance": {"summary": "Mandatory.", "quote": "Attendance is mandatory."},
         "officeHours": []}
        """
        let provider = ScriptedModelProvider(steps: [.respond(json: reply)])

        let fields = try await CourseContractExtractor.modelFields(in: text, provider: provider)

        #expect(fields.weights.map(\.value.name) == ["Homework"])   // "Labs" quote isn't in the syllabus
        #expect(fields.latePolicy?.value == "10% off per day, up to 3 days.")
        #expect(fields.dropRules.count == 1)
        #expect(fields.attendance == nil)                            // invented quote
    }
}
