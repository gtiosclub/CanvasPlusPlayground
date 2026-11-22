//
//  GlobalCalendarManagerTests.swift
//  CanvasPlusPlaygroundTests
//
//  Created by Kareem Alaiwat on 11/22/26.
//

import Foundation
import Testing
@testable import CanvasPlusPlayground

@MainActor
struct GlobalCalendarManagerTests {
    // Thursday, Nov 19 2026, 3:30 PM. Nov 1 and Nov 22 2026 are Sundays.
    private let thursday = DateComponents(calendar: .current, year: 2026, month: 11, day: 19, hour: 15, minute: 30).date!

    private func manager(_ mode: CalendarViewMode) -> GlobalCalendarManager {
        let manager = GlobalCalendarManager()
        manager.currentDate = thursday
        manager.viewMode = mode
        return manager
    }

    private func components(_ date: Date) -> DateComponents {
        Calendar.current.dateComponents([.year, .month, .day, .weekday], from: date)
    }

    @Test func dayModeShowsOnlyTheCurrentDay() {
        let manager = manager(.day)
        #expect(manager.visibleDates.map { components($0).day } == [19])
        #expect(manager.leadingBlankDays == 0)
        #expect(manager.title == "Thursday 11/19")
    }

    @Test func weekModeStartsOnSundayRegardlessOfLocale() {
        let manager = manager(.week)
        #expect(manager.visibleDates.map { components($0).day } == Array(15...21))
        #expect(components(manager.visibleDates[0]).weekday == 1)
        #expect(manager.leadingBlankDays == 0)
        #expect(manager.title == "Week of 11/15")
    }

    @Test func monthModeCoversTheWholeMonth() {
        let manager = manager(.month)
        #expect(manager.visibleDates.count == 30)
        #expect(manager.leadingBlankDays == 0)
        #expect(manager.title == "November 2026")

        manager.step(by: 1)
        // Dec 1 2026 is a Tuesday: two blank cells (Sun, Mon) before it.
        #expect(manager.visibleDates.count == 31)
        #expect(manager.leadingBlankDays == 2)
        #expect(manager.title == "December 2026")
    }

    @Test(arguments: [
        (CalendarViewMode.day, 19),
        (.week, 15),
        (.month, 1),
    ])
    func newItemsDefaultToTheFirstVisibleDay(mode: CalendarViewMode, expectedDay: Int) {
        let manager = manager(mode)
        let date = manager.defaultNewItemDate
        #expect(components(date).month == 11)
        #expect(components(date).day == expectedDay)
    }

    @Test(arguments: [
        (CalendarViewMode.day, 20),
        (.week, 26),
        (.month, 19),
    ])
    func steppingMovesOnePageOfTheCurrentMode(mode: CalendarViewMode, expectedDay: Int) {
        let manager = manager(mode)
        manager.step(by: 1)
        #expect(components(manager.currentDate).day == expectedDay)
        #expect(components(manager.currentDate).month == (mode == .month ? 12 : 11))
    }

    @Test func showDaySwitchesToDayMode() {
        let manager = manager(.month)
        let target = manager.visibleDates[4]
        manager.showDay(target)
        #expect(manager.viewMode == .day)
        #expect(manager.visibleDates == [Calendar.current.startOfDay(for: target)])
    }

    // MARK: - Timeline columns

    private func event(_ id: String, _ start: (Int, Int), _ end: (Int, Int), course: Course) -> CanvasCalendarEvent {
        let cal = Calendar.current
        return CanvasCalendarEvent(
            id: id,
            course: course,
            summary: id,
            startDate: cal.date(bySettingHour: start.0, minute: start.1, second: 0, of: thursday)!,
            endDate: cal.date(bySettingHour: end.0, minute: end.1, second: 0, of: thursday)!,
            location: ""
        )
    }

    private var course: Course { SandboxData.dummyCourses.first! }

    @Test func overlappingEventsSplitTheWidthAndReuseFreedColumns() {
        // The overlap trio from the mock data, plus an unrelated later event.
        let events = [
            event("lecture", (10, 0), (11, 30), course: course),
            event("office", (11, 0), (12, 0), course: course),
            event("study", (11, 30), (12, 15), course: course),
            event("later", (13, 0), (14, 0), course: course),
        ]
        let slots = GlobalCalendarManager.timelineColumns(for: events)

        #expect(slots["lecture"]! == (0, 2))
        #expect(slots["office"]! == (1, 2))
        #expect(slots["study"]! == (0, 2))  // lecture's column is free again at 11:30
        #expect(slots["later"]! == (0, 1))
    }

    @Test func zeroLengthEventsStillCollide() {
        let events = [
            event("lab", (9, 0), (10, 0), course: course),
            event("due", (9, 30), (9, 30), course: course),
            event("lateDue", (23, 59), (23, 59), course: course),
        ]
        let slots = GlobalCalendarManager.timelineColumns(for: events)

        #expect(slots["lab"]! == (0, 2))
        #expect(slots["due"]! == (1, 2))
        #expect(slots["lateDue"]! == (0, 1))
    }

    @Test func everyMockEventGetsASlotWithinBounds() {
        let mocks = GlobalCalendarManager.mockEvents(courses: [course], around: thursday, calendar: .current)
        for day in Set(mocks.map { Calendar.current.startOfDay(for: $0.startDate) }) {
            let events = mocks.filter { Calendar.current.isDate($0.startDate, inSameDayAs: day) }
            let slots = GlobalCalendarManager.timelineColumns(for: events)
            #expect(slots.count == events.count)
            for slot in slots.values {
                #expect(slot.column >= 0 && slot.column < slot.columns)
            }
        }
    }

    // MARK: - To-dos

    private func toDo(_ title: String, due: Date?, location: String? = nil, course: Course?) -> ToDoItem {
        let item = ToDoItem(courseID: 12345, contextName: "Example", title: title, dueDate: due, location: location)
        item.course = course
        return item
    }

    @Test func datedToDosAppearOnTheirDayAndUndatedOrCourselessOnesDoNot() {
        let manager = manager(.day)
        let dated = toDo("Problem set", due: thursday, location: "Klaus", course: course)
        manager.setToDoItems([
            dated,
            toDo("No date", due: nil, course: course),
            toDo("No course", due: thursday, course: nil),
        ], courses: [])

        let toDos = manager.events(on: thursday).filter { $0.id.hasPrefix("todo-") }
        #expect(toDos.map(\.summary) == ["Problem set"])
        #expect(toDos.first?.location == "Klaus")
        #expect(toDos.first?.startDate == thursday)
        #expect(manager.events(on: Calendar.current.date(byAdding: .day, value: 1, to: thursday)!)
            .allSatisfy { !$0.id.hasPrefix("todo-") })
    }

    @Test func userCreatedToDosOpenTheEventDetail() throws {
        let manager = manager(.day)
        manager.setToDoItems([toDo("Study session", due: thursday, course: course)], courses: [])
        let event = try #require(manager.events(on: thursday).first { $0.id.hasPrefix("todo-") })

        guard case .calendarEvent(let routed, _) = manager.destination(for: event) else {
            Issue.record("Expected the event detail destination")
            return
        }
        #expect(routed.id == event.id)
    }

    @Test func replacingToDosDropsRemovedOnes() {
        let manager = manager(.day)
        manager.setToDoItems([toDo("Old", due: thursday, course: course)], courses: [])
        manager.setToDoItems([], courses: [])
        #expect(manager.events(on: thursday).allSatisfy { !$0.id.hasPrefix("todo-") })
    }

    @Test func toDosFetchedBeforeCoursesLoadedStillFindTheirCourse() {
        let manager = manager(.day)
        // The live fetch leaves `course` nil when courses weren't loaded yet; courseID still matches.
        let orphan = ToDoItem(courseID: Int(course.id)!, contextName: "Example", title: "Late link", dueDate: thursday)
        manager.setToDoItems([orphan], courses: SandboxData.dummyCourses)

        let toDo = manager.events(on: thursday).first { $0.id.hasPrefix("todo-") }
        #expect(toDo?.summary == "Late link")
        #expect(toDo?.course.id == course.id)
    }
}
