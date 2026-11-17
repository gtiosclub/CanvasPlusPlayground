//
//  TodaySchedule.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/8/26.
//

import Foundation

/// Date logic for the Today screen. Kept free of UI and model types so it's easy to test.
enum TodaySchedule {
    /// How far ahead the "Due Soon" section looks.
    static let dueSoonWindow: TimeInterval = 48 * 60 * 60

    /// Overdue if the due date has passed, due soon if it's within the next 48 hours,
    /// otherwise `nil` (not shown on Today).
    static func section(forDueDate dueDate: Date?, now: Date) -> TodaySection? {
        guard let dueDate else { return nil }

        if dueDate < now {
            return .overdue
        } else if dueDate <= now.addingTimeInterval(dueSoonWindow) {
            return .dueSoon
        }

        return nil
    }

    /// A short relative label such as "in 5h", "in 35m", "in 2d" or "3h ago".
    static func relativeLabel(for date: Date, now: Date) -> String {
        let seconds = date.timeIntervalSince(now)
        let magnitude = abs(seconds)

        guard magnitude >= 60 else { return "now" }

        let amount: String
        if magnitude < 60 * 60 {
            amount = "\(Int(magnitude / 60))m"
        } else if magnitude < 24 * 60 * 60 {
            amount = "\(Int(magnitude / (60 * 60)))h"
        } else {
            amount = "\(Int(magnitude / (24 * 60 * 60)))d"
        }

        return seconds > 0 ? "in \(amount)" : "\(amount) ago"
    }

    /// The due day and time, such as "today at 11:59 PM", "tomorrow at 9:00 AM"
    /// or "Mon, Oct 12 at 5:00 PM".
    static func dueDateText(for date: Date, now: Date, calendar: Calendar = .current) -> String {
        let time = date.formatted(date: .omitted, time: .shortened)

        let day: String
        if calendar.isDate(date, inSameDayAs: now) {
            day = "today"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
                  calendar.isDate(date, inSameDayAs: tomorrow) {
            day = "tomorrow"
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
                  calendar.isDate(date, inSameDayAs: yesterday) {
            day = "yesterday"
        } else {
            day = date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        }

        return "\(day) at \(time)"
    }

    /// The row subtitle for a to-do, such as "Due today at 11:59 PM · in 5h · CS 1331".
    static func todoDescription(dueDate: Date, courseName: String?, now: Date) -> String {
        var parts = [
            "Due \(dueDateText(for: dueDate, now: now))",
            relativeLabel(for: dueDate, now: now)
        ]

        if let courseName, !courseName.isEmpty {
            parts.append(courseName)
        }

        return parts.joined(separator: " · ")
    }
}

/// The sections shown on the Today screen and widget.
enum TodaySection: CaseIterable {
    case overdue
    case dueSoon
    case calendarEvents
}

/// Load state for a single Today section, so one failed request
/// doesn't hide the sections that did load.
enum TodaySectionState: Equatable {
    case loading
    case loaded
    case failed(String)
}
