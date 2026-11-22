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
}
