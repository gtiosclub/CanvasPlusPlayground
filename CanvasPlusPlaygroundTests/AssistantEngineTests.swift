//
//  AssistantEngineTests.swift
//  CanvasPlusPlaygroundTests
//

import Foundation
import FoundationModels
import Testing
@testable import CanvasPlusPlayground

private let now = Date(timeIntervalSince1970: 1_790_000_000)
private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/New_York")!
    return calendar
}()

private func assignment(_ id: String, days: Double, score: Double? = nil, points: Double = 100, status: SubmissionStatus? = nil, course: String = "1") -> Evidence {
    Evidence(
        ref: .assignment(id: id, courseID: course),
        title: "Assignment \(id)",
        snippet: nil,
        facts: EvidenceFacts(
            courseName: "CS 1332",
            dueDate: now.addingTimeInterval(days * 86_400),
            pointsPossible: points,
            score: score,
            submissionStatus: status,
            gradedAt: score == nil ? nil : now.addingTimeInterval((days + 1) * 86_400)
        )
    )
}

@MainActor
private final class FakeSource: AgentDataSource {
    var assignmentList: [Evidence] = []
    var announcementList: [Evidence] = []
    var eventList: [Evidence] = []

    func courses() async throws -> [Evidence] {
        [Evidence(ref: .course(id: "1"), title: "Data Structures", snippet: "CS 1332 · Fall 2026")]
    }
    func assignments(courseID: String) async throws -> [Evidence] { assignmentList }
    func announcements(courseID: String) async throws -> [Evidence] { announcementList }
    func calendarEvents(courseID: String) async throws -> [Evidence] { eventList }
    func toDos() async throws -> [Evidence] { [] }
    func files(courseID: String) async throws -> [Evidence] { [] }
}

@available(iOS 26.0, macOS 26.0, *)
private struct Unavailable: AgentModelProvider {
    let tier = AgentTier.onDevice
    let isAvailable = false
    func respond<Output: Generable>(to prompt: AgentPrompt, tools: [any Tool], generating type: Output.Type) async throws -> AgentResponse<Output> {
        throw AgentModelError.unavailable("test")
    }
}

@available(iOS 26.0, macOS 26.0, *)
@MainActor
private func engine(_ source: FakeSource, model: (any AgentModelProvider)? = nil, groups: [GradeGroupScore] = []) -> AssistantEngine {
    var engine = AssistantEngine(dataSource: source)
    engine.retrievePassages = { _, _ in [] }
    engine.gradeGroups = { _ in groups }
    engine.router = AgentModelRouter(onDevice: model ?? Unavailable(), cloud: nil, noModel: NoModelProvider())
    engine.runtime = { AgentRuntime(provider: $0, store: AgentRunStore(inMemory: true), ledger: ExecutionLedger(store: nil)) }
    engine.now = { now }
    engine.calendar = calendar
    return engine
}

struct AssistantIntentTests {
    @Test(arguments: [
        ("What assignments have been graded?", AssistantIntent.graded),
        ("What's my grade in CS 1332?", .grade),
        ("What does my next week look like?", .week),
        ("Did anything change in my courses?", .changes),
        ("Any new announcements?", .announcements),
        ("What should I do first?", .urgent),
        ("Am I missing any work?", .missing),
        ("Where is the lab room?", .general),
        ("What classes do I have today", .today),
        ("What's due today?", .today),
    ])
    func classifies(_ question: String, expected: AssistantIntent) {
        #expect(AssistantIntent.classify(question) == expected)
    }
}

struct AssistantRelevanceTests {
    @Test func significantTermsDropQuestionWords() {
        #expect(AssistantEngine.significantTerms(in: "What classes do I have today?").isEmpty)
        #expect(AssistantEngine.significantTerms(in: "When is the lab policy due?") == ["lab", "policy", "due"])
    }
}

struct AssistantTextTests {
    @Test func removesRecordIDsAndWritesDatesOut() {
        let text = AssistantEngine.readable("PS5 is due on 2026-11-22T23:59:00-05:00 (assignment:2).", calendar: calendar)
        #expect(!text.contains("assignment:"))
        #expect(!text.contains("2026-11-22"))
        #expect(text.contains("Sunday"))
        #expect(text.hasSuffix("PM."))
    }

    @Test func leavesOrdinaryTextAlone() {
        #expect(AssistantEngine.readable("You have 2 assignments (both online).", calendar: calendar) == "You have 2 assignments (both online).")
    }

    @Test func weekLayoutGroupsByDayInOrder() {
        let items = [assignment("b", days: 2), assignment("a", days: 0.1), assignment("c", days: 2.1), assignment("old", days: -3)]
        let days = WeekLayout.days(items, from: now, calendar: calendar)
        #expect(days.count == 2)
        #expect(days[1].items.map(\.title) == ["Assignment b", "Assignment c"])
    }

    @Test func examsAreSpotted() {
        #expect(WeekLayout.isExam(Evidence(ref: .assignment(id: "1", courseID: "1"), title: "Midterm 2", snippet: nil)))
        #expect(!WeekLayout.isExam(Evidence(ref: .assignment(id: "1", courseID: "1"), title: "Lab 3", snippet: nil)))
    }

    @Test func overallGradeIsWeightedWhenTheCourseWeightsGroups() {
        let groups = [
            GradeGroupScore(id: "1", courseID: "1", courseName: "c", name: "Homework", weight: 40, earned: 90, possible: 100),
            GradeGroupScore(id: "2", courseID: "1", courseName: "c", name: "Exams", weight: 60, earned: 80, possible: 100),
            GradeGroupScore(id: "3", courseID: "1", courseName: "c", name: "Final", weight: 0, earned: 0, possible: 0),
        ]
        #expect(GradeGroupScore.overall(groups) == 84)
        #expect(groups[2].percent == nil)
    }
}

@MainActor
struct AssistantEngineTests {
    @Test func gradedQuestionsListGradedWorkWithoutAModel() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let source = FakeSource()
        source.assignmentList = [
            assignment("1", days: 3),
            assignment("2", days: -4, score: 93, status: .graded),
            assignment("3", days: -2, score: 10, points: 10, status: .graded),
            assignment("4", days: -1, status: .submitted),
        ]

        let reply = try await engine(source).answer("What assignments have been graded?", context: .dashboard)

        #expect(reply.tier == .none)
        #expect(reply.sentences.first?.text == "Here are your most recent assignments that have been graded.")
        guard case .records(let rows)? = reply.block else {
            Issue.record("Expected a records block")
            return
        }
        // Most recently graded first; upcoming and ungraded work isn't listed.
        #expect(rows.map(\.id) == ["assignment:3", "assignment:2"])
        #expect(reply.runID != nil)
    }

    @Test func weekQuestionsDrawAWeek() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let source = FakeSource()
        source.assignmentList = [assignment("1", days: 1), assignment("2", days: 3), assignment("late", days: 10)]

        let reply = try await engine(source).answer("What does my next week look like?", context: .dashboard)

        guard case .week(let days)? = reply.block else {
            Issue.record("Expected a week block")
            return
        }
        #expect(days.flatMap(\.items).map(\.id) == ["assignment:1", "assignment:2"])
        #expect(reply.sentences.first?.text.contains("2 assignments") == true)
    }

    @Test func gradeQuestionsOnACoursePageBreakDownTheGrade() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let groups = [
            GradeGroupScore(id: "g1", courseID: "1", courseName: "Data Structures", name: "Labs", weight: 50, earned: 100, possible: 100),
            GradeGroupScore(id: "g2", courseID: "1", courseName: "Data Structures", name: "Exams", weight: 50, earned: 80, possible: 100),
        ]
        let page = AssistantPageContext(kind: .course, courseID: "1", courseName: "Data Structures")

        let reply = try await engine(FakeSource(), groups: groups).answer("What's my grade?", context: page)

        guard case let .grade(_, overall, rows)? = reply.block else {
            Issue.record("Expected a grade block")
            return
        }
        #expect(overall == 90)
        #expect(rows.map(\.title) == ["Labs", "Exams"])
        #expect(reply.sentences.first?.text.contains("90%") == true)
    }

    @Test func theGateHidesSentencesWithMadeUpCitations() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let source = FakeSource()
        source.assignmentList = [assignment("2", days: -4, score: 93, status: .graded)]
        let json = """
        {"sentences": [
            {"text": "Assignment 2 got 93% (assignment:2).", "citedIDs": ["assignment:2"]},
            {"text": "You also aced the final.", "citedIDs": ["assignment:999"]}
         ],
         "showIDs": ["assignment:2", "assignment:999"],
         "followUps": ["What's my grade overall?"],
         "confidence": "high"}
        """
        let model = ScriptedModelProvider(steps: [.respond(json: json)])

        let reply = try await engine(source, model: model).answer("What assignments have been graded?", context: .dashboard)

        #expect(reply.tier == .onDevice)
        #expect(reply.sentences.map(\.text) == ["Assignment 2 got 93%."])
        #expect(reply.droppedCount == 1)
        #expect(reply.followUps == ["What's my grade overall?"])
        guard case .records(let rows)? = reply.block else {
            Issue.record("Expected a records block")
            return
        }
        #expect(rows.map(\.id) == ["assignment:2"])
    }

    @Test func todayWithNothingScheduledSaysSoHonestly() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let source = FakeSource()
        source.assignmentList = [assignment("far", days: 5)]

        let reply = try await engine(source).answer("What classes do I have today", context: .dashboard)

        #expect(reply.block == nil)
        #expect(reply.sentences.isEmpty)
        #expect(reply.note?.contains("class meeting times") == true)
        #expect(!reply.canTryCloud)
    }

    @Test func generalQuestionsNeverListIrrelevantPassages() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let welcome = Evidence(ref: .passage(sourceID: "page:1", ordinal: 0, courseID: "1"), title: "Welcome", snippet: "Welcome to the course! We have labs every week.")
        let labs = Evidence(ref: .passage(sourceID: "page:2", ordinal: 0, courseID: "1"), title: "Lab Policy", snippet: "Labs are due Fridays.")
        var e = engine(FakeSource())
        e.retrievePassages = { _, _ in [welcome, labs] }

        // Nothing in the records mentions "parking": no rows, an honest note.
        let none = try await e.answer("Where do I park?", context: .dashboard)
        #expect(none.block == nil)
        #expect(none.note == "I couldn't find that in your synced courses.")

        // "policy" matches the lab policy page only.
        let some = try await e.answer("What is the lab policy?", context: .dashboard)
        guard case .records(let rows)? = some.block else {
            Issue.record("Expected records")
            return
        }
        #expect(rows.map(\.id).contains(labs.id))
    }

    @Test func aModelThatFindsNothingIsShownAsANoteNotHidden() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let labs = Evidence(ref: .passage(sourceID: "page:2", ordinal: 0, courseID: "1"), title: "Lab Policy", snippet: "Labs are due Fridays.")
        let json = #"{"sentences": [{"text": "The records don't say when labs start.", "citedIDs": []}], "showIDs": ["passage:page:2#0"], "followUps": [], "confidence": "low"}"#
        var e = engine(FakeSource(), model: ScriptedModelProvider(steps: [.respond(json: json)]))
        e.retrievePassages = { _, _ in [labs] }

        let reply = try await e.answer("When do labs start?", context: .dashboard)

        #expect(reply.note == "The records don't say when labs start.")
        #expect(reply.droppedCount == 0)
        #expect(reply.block == nil)
        #expect(reply.canTryCloud)
    }

    @Test func nothingFoundOffersNoCloud() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let reply = try await engine(FakeSource()).answer("Any new announcements?", context: .dashboard)
        #expect(reply.sentences.isEmpty && reply.block == nil)
        #expect(reply.note == "I couldn't find that in your synced courses.")
        #expect(!reply.canTryCloud)
    }
}

struct AssistantSuggestionTests {
    @Test func everyScreenHasQuestions() {
        for kind in [AssistantPageContext.Kind.dashboard, .course, .announcements, .toDos, .assignments, .assignment, .quiz, .grades, .calendar, .other] {
            #expect(!AssistantSuggestions.faq(for: AssistantPageContext(kind: kind)).isEmpty)
        }
    }

    @Test func itemScreensGetQuestionsAboutTheItem() {
        let context = AssistantPageContext(kind: .assignment, courseID: "1", itemTitle: "Lab 3")
        #expect(AssistantSuggestions.templates(for: context).map(\.text) == ["When is Lab 3 due?", "How much is Lab 3 worth?"])
        #expect(AssistantSuggestions.templates(for: .dashboard).isEmpty)
    }

    @Test func coursePagesNameTheCourse() {
        let context = AssistantPageContext(kind: .course, courseID: "1", courseName: "CS 1332")
        #expect(AssistantSuggestions.faq(for: context).first?.text == "What's due in CS 1332 next week?")
    }
}

struct AssistantTextCleanupTests {
    @Test func noDanglingDashesWhereIDsWere() {
        let calendar = Calendar(identifier: .gregorian)
        #expect(AssistantEngine.readable("The quiz due soon— [assignment:106] —is a must-do.", calendar: calendar) == "The quiz due soon is a must-do.")
        #expect(AssistantEngine.readable("Lab 2—the hard one—is due Friday.", calendar: calendar) == "Lab 2 the hard one is due Friday.")
    }
}
