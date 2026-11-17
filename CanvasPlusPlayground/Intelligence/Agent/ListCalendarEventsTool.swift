//
//  ListCalendarEventsTool.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/8/26.
//

import Foundation
import FoundationModels

/// Lists calendar events from the course ICS feeds, earliest first.
@available(iOS 26.0, macOS 26.0, *)
struct ListCalendarEventsTool: AgentTool {
    @Generable
    struct Arguments {
        @Guide(description: "A course id or name from listCourses. Leave empty to search every course.")
        var course: String?

        @Guide(description: "How many days ahead to look, where 0 means today only. Defaults to 7.")
        var daysAhead: Int?
    }

    static let defaultDaysAhead = 7
    static let maxDaysAhead = 60

    let name = "listCalendarEvents"
    let description = "Lists course calendar events (lectures, exams, office hours) with start and end times and locations, earliest first."

    let dataSource: any AgentDataSource
    var now: @Sendable () -> Date = { .now }
    var calendar: Calendar = .current

    func evidence(for arguments: Arguments) async throws -> [Evidence] {
        let days = min(max(arguments.daysAhead ?? Self.defaultDaysAhead, 0), Self.maxDaysAhead)
        let startOfToday = calendar.startOfDay(for: now())
        let end = calendar.date(byAdding: .day, value: days + 1, to: startOfToday) ?? startOfToday

        let courseIDs = try await AgentReadTools.courseIDs(for: arguments.course, in: dataSource)
        let events = try await AgentReadTools.collect(courseIDs) { try await dataSource.calendarEvents(courseID: $0) }

        return Array(
            events
                .filter { event in
                    guard let start = event.facts.startDate else { return false }
                    return start >= startOfToday && start < end
                }
                .sorted { ($0.facts.startDate ?? .distantFuture) < ($1.facts.startDate ?? .distantFuture) }
                .prefix(AgentReadTools.maxResults)
        )
    }
}
