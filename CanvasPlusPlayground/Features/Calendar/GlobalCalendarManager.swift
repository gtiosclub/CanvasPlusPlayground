//
//  GlobalCalendarManager.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/25/25.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class GlobalCalendarManager {
    var currentDate: Date = .now
    // Day is the only mode where individual events are tappable.
    var viewMode: CalendarViewMode = .day

    // Weeks start on Sunday regardless of locale, per the design.
    let calendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        return calendar
    }()

    private var courseSchedules: [CanvasCourseSchedule] = []
    private var extraEvents: [CanvasCalendarEvent] = []

    // MARK: - Visible range

    /// The day, Sunday-start week, or month containing `currentDate`.
    var visibleInterval: DateInterval {
        calendar.dateInterval(of: viewMode.component, for: currentDate)
            ?? DateInterval(start: calendar.startOfDay(for: currentDate), duration: 86_400)
    }

    var visibleDates: [Date] {
        let interval = visibleInterval
        let dayCount = calendar.dateComponents([.day], from: interval.start, to: interval.end).day ?? 1
        return (0..<dayCount).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    /// Empty cells before the 1st so it lands under the right weekday column (0 for day/week).
    var leadingBlankDays: Int {
        guard viewMode == .month else { return 0 }
        let weekday = calendar.component(.weekday, from: visibleInterval.start)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    var title: String {
        let start = visibleInterval.start
        switch viewMode {
        case .day:
            return "\(start.formatted(.dateTime.weekday(.wide))) \(start.formatted(.dateTime.month(.defaultDigits).day()))"
        case .week:
            return "Week of \(start.formatted(.dateTime.month(.defaultDigits).day()))"
        case .month:
            return start.formatted(.dateTime.month(.wide).year())
        }
    }

    /// First day of the visible range (the day, its Sunday, or the 1st) at the next full hour.
    var defaultNewItemDate: Date {
        let nextHour = calendar.component(.hour, from: .now) + 1
        return calendar.date(byAdding: .hour, value: nextHour, to: visibleInterval.start) ?? visibleInterval.start
    }

    // MARK: - Navigation

    func step(by pages: Int) {
        if let newDate = calendar.date(byAdding: viewMode.component, value: pages, to: currentDate) {
            currentDate = newDate
        }
    }

    func setToNow() {
        currentDate = .now
    }

    func showDay(_ date: Date) {
        currentDate = date
        viewMode = .day
    }

    // MARK: - Events

    func events(on day: Date) -> [CanvasCalendarEvent] {
        let weekday = calendar.component(.weekday, from: day)
        let meetings = courseSchedules.flatMap { schedule in
            schedule.meetings
                .filter { $0.weekday.number(calendar: calendar) == weekday }
                .compactMap { event(for: $0, course: schedule.course, on: day) }
        }
        let extras = extraEvents.filter { calendar.isDate($0.startDate, inSameDayAs: day) }
        return (meetings + extras).sorted { $0.startDate < $1.startDate }
    }

    /// Class meetings repeat weekly, so they're stored as weekday templates and dated on demand.
    private func event(for meeting: CanvasCourseScheduleMeeting, course: Course, on day: Date) -> CanvasCalendarEvent? {
        guard let startDate = calendar.date(
                bySettingHour: meeting.startTime.hour ?? 0, minute: meeting.startTime.minute ?? 0, second: 0, of: day
              ),
              let endDate = calendar.date(
                bySettingHour: meeting.endTime.hour ?? 0, minute: meeting.endTime.minute ?? 0, second: 0, of: day
              ) else { return nil }

        return CanvasCalendarEvent(
            id: "\(course.id)-\(startDate.timeIntervalSince1970)-\(meeting.location)",
            course: course,
            summary: course.displayName,
            startDate: startDate,
            endDate: endDate,
            location: meeting.location
        )
    }

    /// Side-by-side placement for the day timeline: each event's column, and how many columns its
    /// group of time-overlapping events splits the width into. Missing events default to full width.
    nonisolated static func timelineColumns(
        for events: [CanvasCalendarEvent]
    ) -> [CanvasCalendarEvent.ID: (column: Int, columns: Int)] {
        // Zero-length "due" events still draw ~24pt tall, so give them a visual length to collide with.
        let minimumVisualDuration: TimeInterval = 30 * 60

        var slots: [CanvasCalendarEvent.ID: (column: Int, columns: Int)] = [:]
        var columnEnds: [Date] = []  // latest end time in each column of the current cluster
        var cluster: [(id: CanvasCalendarEvent.ID, column: Int)] = []
        var clusterEnd = Date.distantPast

        // Every event in a cluster of transitively-overlapping events shares the cluster's column count.
        func closeCluster() {
            for member in cluster {
                slots[member.id] = (member.column, columnEnds.count)
            }
            cluster = []
            columnEnds = []
        }

        for event in events.sorted(by: { $0.startDate < $1.startDate }) {
            let end = max(event.endDate, event.startDate.addingTimeInterval(minimumVisualDuration))
            if event.startDate >= clusterEnd {
                closeCluster()
            }

            // Reuse the first column that's free by this start time, else open a new one.
            let column = columnEnds.firstIndex { $0 <= event.startDate } ?? columnEnds.count
            if column == columnEnds.count {
                columnEnds.append(end)
            } else {
                columnEnds[column] = end
            }
            cluster.append((event.id, column))
            clusterEnd = max(clusterEnd, end)
        }
        closeCluster()

        return slots
    }

    func getCalendarEventsForCourses(courses: [Course]) async {
        var schedules: [CanvasCourseSchedule] = []
        for course in courses {
            // TODO: ERROR HANDLING
            if let schedule = try? await GTSchedulerParser.shared.getCanvasCourseScheduleMeetings(course: course) {
                schedules.append(schedule)
            }
        }
        courseSchedules = schedules

        #if DEBUG
        extraEvents = Self.mockEvents(courses: courses, around: .now, calendar: calendar)
        #endif
    }
}
