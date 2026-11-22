//
//  CrunchTests.swift
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

/// Monday, Nov 2 2026, 8:00 AM Eastern.
private let start = calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 8))!

private func day(_ offset: Int, hour: Int = 23, minute: Int = 59) -> Date {
    calendar.date(byAdding: .day, value: offset, to: calendar.date(bySettingHour: hour, minute: minute, second: 0, of: start)!)!
}

private func item(_ id: String, _ kind: WorkloadItem.Kind = .assignment, due offset: Int, points: Double? = nil, weight: Double? = nil, groupPoints: Double? = nil) -> WorkloadItem {
    let evidence = Evidence(ref: .assignment(id: id, courseID: "1"), title: "Item \(id)", snippet: nil, facts: EvidenceFacts(dueDate: day(offset)))
    return WorkloadItem(id: evidence.id, title: "Item \(id)", courseName: "CS 1331", kind: kind, date: day(offset), pointsPossible: points, groupWeight: weight, groupPoints: groupPoints, evidence: evidence)
}

struct WorkloadItemTests {
    @Test func examsWeighMoreThanAssignmentsWhichWeighMoreThanEvents() {
        #expect(item("e", .exam, due: 3).effort > item("a", due: 3).effort)
        #expect(item("a", due: 3).effort > item("v", .event, due: 3).effort)
    }

    @Test func gradeShareBeatsRawPoints() {
        // 10 points in a group of 100 worth 30% = 3% of the grade.
        let small = item("a", due: 3, points: 10, weight: 30, groupPoints: 100)
        // 10 points in a group of 20 worth 30% = 15% of the grade.
        let big = item("b", due: 3, points: 10, weight: 30, groupPoints: 20)
        #expect(small.gradeShare == 3)
        #expect(big.gradeShare == 15)
        #expect(big.effort > small.effort)
    }

    @Test(arguments: [
        ("Midterm 1", WorkloadItem.Kind.assignment, WorkloadItem.Kind.exam),
        ("Final Exam Review Session", .event, .exam),
        ("Quiz 4", .assignment, .quiz),
        ("Homework 3", .assignment, .assignment),
        ("Office hours", .event, .event),
    ])
    func infersKindFromTitle(_ title: String, fallback: WorkloadItem.Kind, expected: WorkloadItem.Kind) {
        #expect(WorkloadItem.kind(forTitle: title, default: fallback) == expected)
    }
}

struct WorkloadCurveTests {
    @Test func coversTwentyOneDaysFromTheStartOfToday() {
        let curve = WorkloadCurve(items: [], from: start, calendar: calendar)
        #expect(curve.days.count == 21)
        #expect(curve.days.first?.date == calendar.startOfDay(for: start))
        #expect(curve.crunchDays.isEmpty)
    }

    @Test func spreadsEffortOverTheLeadUpWithMostOnTheDueDay() {
        let assignment = item("a", due: 5)
        let curve = WorkloadCurve(items: [assignment], from: start, calendar: calendar)
        let loads = curve.days.map(\.load)

        // Lead of 3 days: days 2, 3, 4, 5 carry 1, 2, 3, 4 tenths of the effort.
        #expect(loads[0] == 0 && loads[1] == 0)
        #expect(abs(loads[2] - assignment.effort * 0.1) < 1e-9)
        #expect(abs(loads[5] - assignment.effort * 0.4) < 1e-9)
        #expect(abs(loads.reduce(0, +) - assignment.effort) < 1e-9)
        #expect(curve.days[5].dueItems.map(\.id) == [assignment.id])
    }

    @Test func leadUpThatStartsBeforeTodayOnlyCountsTheVisibleDays() {
        let curve = WorkloadCurve(items: [item("a", due: 1)], from: start, calendar: calendar)
        #expect(curve.days[0].load > 0)
        #expect(curve.days.map(\.load).reduce(0, +) < item("a", due: 1).effort)
    }

    @Test func pastItemsAreIgnored() {
        let curve = WorkloadCurve(items: [item("old", due: -2)], from: start, calendar: calendar)
        #expect(curve.days.allSatisfy { $0.load == 0 })
    }

    @Test func aPileUpIsACrunchButOneAssignmentIsNot() {
        let quiet = WorkloadCurve(items: [item("a", due: 4)], from: start, calendar: calendar)
        #expect(quiet.crunchDays.isEmpty)

        let busy = WorkloadCurve(
            // An exam worth 25% of the grade plus two assignments on the same day.
            items: [item("e", .exam, due: 6, points: 100, weight: 25, groupPoints: 100), item("a", due: 6), item("b", due: 6), item("c", due: 12)],
            from: start,
            calendar: calendar
        )
        #expect(busy.crunchDays.map(\.date) == [calendar.startOfDay(for: day(6))])
    }
}

struct CrunchPlannerTests {
    var busyCurve: WorkloadCurve {
        WorkloadCurve(
            items: [item("exam", .exam, due: 8, points: 100, weight: 25, groupPoints: 100), item("a", due: 8), item("b", due: 8), item("later", due: 14)],
            from: start,
            calendar: calendar
        )
    }

    @Test func baselineStartsCrunchWorkEarlyOnALighterDay() throws {
        let plan = CrunchPlanner.baseline(for: busyCurve, today: start, calendar: calendar)
        let early = plan.suggestions.compactMap { suggestion -> (String, Date)? in
            if case .startEarly(let date) = suggestion.kind { (suggestion.item.id, date) } else { nil }
        }

        #expect(plan.source == .baseline)
        #expect(!early.isEmpty)
        #expect(early.count <= CrunchPlanner.maxPerCrunchDay)
        let crunch = try #require(busyCurve.crunchDays.first)
        for (_, date) in early {
            #expect(date < crunch.date)
            #expect(date >= calendar.startOfDay(for: start))
            #expect(busyCurve.days.first { $0.date == date }?.isCrunch == false)
        }
    }

    @Test func withoutCrunchDaysThePlanUsesTheBusiestDays() throws {
        // Two assignments the same day: busy (load ~1.04) but well under the crunch floor.
        let curve = WorkloadCurve(items: [item("a", due: 6, points: 50), item("b", due: 6)], from: start, calendar: calendar)
        #expect(curve.crunchDays.isEmpty)
        #expect(curve.focusDays.map(\.date) == [calendar.startOfDay(for: day(6))])

        let plan = CrunchPlanner.baseline(for: curve, today: start, calendar: calendar)
        let first = try #require(plan.suggestions.first)
        guard case .startEarly(let date) = first.kind else {
            Issue.record("Expected a start-early suggestion")
            return
        }
        #expect(date < calendar.startOfDay(for: day(6)))
        #expect(first.reason.contains("busiest"))
        #expect(CrunchPlanner.promptText(for: curve, today: start, calendar: calendar).contains("busiest days"))
    }

    @Test func baselineIsEmptyWhenNothingIsBusy() {
        let curve = WorkloadCurve(items: [item("a", due: 4)], from: start, calendar: calendar)
        #expect(CrunchPlanner.baseline(for: curve, today: start, calendar: calendar).suggestions.isEmpty)
    }

    @Test func startEarlyBecomesAReminderAtNineOnThatDay() throws {
        let plan = CrunchPlanner.baseline(for: busyCurve, today: start, calendar: calendar)
        let actions = plan.proposedActions(now: start, calendar: calendar)
        let first = try #require(actions.first)

        guard case .reminder(let date) = first.kind else {
            Issue.record("Expected a reminder")
            return
        }
        #expect(calendar.component(.hour, from: date) == 9)
        #expect(date > start)
        #expect(actions.count == plan.suggestions.filter { if case .startEarly = $0.kind { true } else { false } }.count)
    }

    @Test func promptListsDaysAndCrunchItemsById() {
        let text = CrunchPlanner.promptText(for: busyCurve, today: start, calendar: calendar)
        #expect(text.contains("Today is 2026-11-02."))
        #expect(text.contains("2026-11-10"))
        #expect(text.contains("[assignment:exam]"))
        #expect(text.contains(" *"))
    }

    @Test func parsesAndFormatsDays() {
        #expect(CrunchPlanner.isoDay(start, calendar: calendar) == "2026-11-02")
        #expect(CrunchPlanner.parseDay("2026-11-05", calendar: calendar).map { calendar.component(.day, from: $0) } == 5)
        #expect(CrunchPlanner.parseDay("Thursday", calendar: calendar) == nil)
    }

    @Test func modelSuggestionsAreCheckedAgainstTheCurve() throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let curve = busyCurve
        let crunchDay = CrunchPlanner.isoDay(curve.crunchDays[0].date, calendar: calendar)

        let json = """
        {"items": [
          {"id": "assignment:a", "kind": "startEarly", "startDay": "2026-11-04", "reason": "Start Wednesday."},
          {"id": "assignment:a", "kind": "warning", "reason": "duplicate"},
          {"id": "assignment:made-up", "kind": "warning", "reason": "not an item"},
          {"id": "assignment:b", "kind": "startEarly", "startDay": "2026-10-30", "reason": "before today"},
          {"id": "assignment:exam", "kind": "startEarly", "startDay": "\(crunchDay)", "reason": "on the crunch day"},
          {"id": "assignment:later", "kind": "canSlip", "reason": "Later is fine."},
          {"id": "assignment:b", "kind": "procrastinate", "reason": "unknown kind"}
        ]}
        """
        let proposals = try CrunchPlanner.ModelPlan(GeneratedContent(json: json)).items

        let kept = CrunchPlanner.validated(proposals, curve: curve, today: start, calendar: calendar)
        #expect(kept.map(\.item.id) == ["assignment:a", "assignment:later"])
        #expect(kept.first?.reason == "Start Wednesday.")
    }
}
