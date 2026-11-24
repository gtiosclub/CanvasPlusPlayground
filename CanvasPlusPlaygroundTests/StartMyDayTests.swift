//
//  StartMyDayTests.swift
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

private func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
}

/// Saturday Nov 21 2026, 9:00 AM.
private let morning = at(21, 9)

private func schedule(hour: Int = 10, minute: Int = 0) -> DayBriefSchedule {
    let schedule = DayBriefSchedule(defaults: UserDefaults(suiteName: "day-\(UUID())")!)
    schedule.hour = hour
    schedule.minute = minute
    return schedule
}

private func item(_ id: String, due: Date? = nil, start: Date? = nil, posted: Date? = nil, kind: EvidenceKind = .assignment,
                  status: SubmissionStatus? = nil, score: Double? = nil, gradedAt: Date? = nil) -> Evidence {
    let ref: EvidenceRef = switch kind {
    case .announcement: .announcement(id: id, courseID: "1")
    case .calendarEvent: .calendarEvent(uid: id, courseID: "1")
    default: .assignment(id: id, courseID: "1")
    }
    return Evidence(ref: ref, title: "Item \(id)", snippet: nil, facts: EvidenceFacts(
        dueDate: due, startDate: start, postedAt: posted, pointsPossible: 100, score: score, submissionStatus: status, gradedAt: gradedAt
    ))
}

struct DayBriefScheduleTests {
    @Test func defaultsToTenAM() {
        let fresh = DayBriefSchedule(defaults: UserDefaults(suiteName: "day-\(UUID())")!)
        #expect(fresh.refreshTime(on: morning, calendar: calendar) == at(21, 10))
    }

    @Test func beforeTheRefreshTimeYesterdaysBriefIsStillCurrent() {
        let s = schedule()
        #expect(s.latestRefresh(before: morning, calendar: calendar) == at(20, 10))
        #expect(!s.isDue(lastGenerated: at(20, 10, 5), now: morning, calendar: calendar))
        #expect(s.isDue(lastGenerated: at(20, 9), now: morning, calendar: calendar))
    }

    @Test func afterTheRefreshTimeABriefFromBeforeItIsStale() {
        let s = schedule()
        #expect(s.isDue(lastGenerated: at(21, 9, 30), now: at(21, 10, 1), calendar: calendar))
        #expect(!s.isDue(lastGenerated: at(21, 10, 0), now: at(21, 15), calendar: calendar))
    }

    @Test func noBriefYetMeansMakeOneNow() {
        #expect(schedule().isDue(lastGenerated: nil, now: morning, calendar: calendar))
    }

    @Test func theTimeIsCustomizable() {
        let s = schedule(hour: 7, minute: 30)
        #expect(s.nextRefresh(after: morning, calendar: calendar) == at(22, 7, 30))
        #expect(s.nextRefresh(after: at(21, 7), calendar: calendar) == at(21, 7, 30))
    }
}

struct DayBriefSectionTests {
    @Test func sortsRecordsIntoSections() {
        let records = [
            item("late", due: at(20, 23, 59)),
            item("tonight", due: at(21, 23, 59)),
            item("monday", due: at(23, 12)),
            item("far", due: at(28, 12)),
            item("done", due: at(21, 20), status: .submitted),
            item("graded", due: at(19, 12), status: .graded, score: 90, gradedAt: at(20, 18)),
            item("lecture", start: at(21, 14), kind: .calendarEvent),
            item("tomorrow-event", start: at(22, 14), kind: .calendarEvent),
            item("news", posted: at(21, 7), kind: .announcement),
            item("old-news", posted: at(18, 7), kind: .announcement),
        ]

        let sections = DayBriefEngine.sections(from: records, now: morning, calendar: calendar)
        let byKind = Dictionary(uniqueKeysWithValues: sections.map { ($0.kind, $0.items.map(\.title)) })

        #expect(sections.map(\.kind) == [.overdue, .dueToday, .events, .comingUp, .graded, .announcements])
        #expect(byKind[.overdue] == ["Item late"])
        #expect(byKind[.dueToday] == ["Item tonight"])
        #expect(byKind[.events] == ["Item lecture"])
        #expect(byKind[.comingUp] == ["Item monday"])
        #expect(byKind[.graded] == ["Item graded"])
        #expect(byKind[.announcements] == ["Item news"])
    }

    @Test func sameTitleIsListedOnce() {
        let records = [item("x", due: at(21, 23)), item("x", due: at(21, 23))]
        #expect(DayBriefEngine.sections(from: records, now: morning, calendar: calendar).flatMap(\.items).count == 1)
    }

    @Test func templateCountsWhatMatters() {
        let sections = DayBriefEngine.sections(from: [item("a", due: at(21, 23)), item("b", due: at(22, 12))], now: morning, calendar: calendar)
        let text = DayBriefEngine.templateSummary(sections).first?.text ?? ""
        #expect(text == "You have 1 due today and 1 coming up in the next two days.")
        #expect(DayBriefEngine.templateSummary([]).first?.text.hasPrefix("Nothing due today") == true)
    }

    @Test func briefsSurviveTheStore() {
        let store = DayBriefStore(url: URL.temporaryDirectory.appending(path: "brief-\(UUID()).json"))
        let brief = DayBrief(generatedAt: morning, summary: [.init(text: "Hi", evidenceIDs: [])], sections: [], tier: .none, runID: nil)
        store.save(brief)
        #expect(store.load() == brief)
    }
}

@MainActor
private final class DaySource: AgentDataSource {
    var assignmentList: [Evidence] = []
    func courses() async throws -> [Evidence] { [Evidence(ref: .course(id: "1"), title: "CS 1332", snippet: nil)] }
    func assignments(courseID: String) async throws -> [Evidence] { assignmentList }
    func announcements(courseID: String) async throws -> [Evidence] { [] }
    func calendarEvents(courseID: String) async throws -> [Evidence] { [] }
    func toDos() async throws -> [Evidence] { [] }
    func files(courseID: String) async throws -> [Evidence] { [] }
}

@MainActor
struct DayBriefEngineTests {
    @Test func buildsABriefThroughTheRuntimeWithAModel() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let source = DaySource()
        let now = Date.now
        source.assignmentList = [item("1", due: now.addingTimeInterval(3_600))]
        let json = #"{"sentences": [{"text": "Item 1 is due within the hour (assignment:1).", "citedIDs": ["assignment:1"]}, {"text": "Also study.", "citedIDs": ["assignment:9"]}]}"#

        var engine = DayBriefEngine(dataSource: source)
        engine.router = AgentModelRouter(onDevice: ScriptedModelProvider(steps: [.respond(json: json)]), cloud: nil)
        engine.runtime = { AgentRuntime(provider: $0, store: AgentRunStore(inMemory: true), ledger: ExecutionLedger(store: nil)) }

        let brief = try await engine.brief()

        #expect(brief.tier == .onDevice)
        #expect(brief.summary.map(\.text) == ["Item 1 is due within the hour."])
        #expect(brief.sections.flatMap(\.items).map(\.id).contains("assignment:1"))
        #expect(brief.runID != nil)
    }
}
