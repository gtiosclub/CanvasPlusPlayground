//
//  ListAnnouncementsTool.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/8/26.
//

import Foundation
import FoundationModels

/// Lists recent announcements, newest first.
@available(iOS 26.0, macOS 26.0, *)
struct ListAnnouncementsTool: AgentTool {
    @Generable
    struct Arguments {
        @Guide(description: "A course id or name from listCourses. Leave empty to search every course.")
        var course: String?

        @Guide(description: "How many days back to look. Defaults to 14.")
        var daysBack: Int?
    }

    static let defaultDaysBack = 14
    static let maxDaysBack = 120

    let name = "listAnnouncements"
    let description = "Lists recent course announcements with when they were posted and a short excerpt, newest first."

    let dataSource: any AgentDataSource
    var now: @Sendable () -> Date = { .now }

    func evidence(for arguments: Arguments) async throws -> [Evidence] {
        let now = now()
        let days = min(max(arguments.daysBack ?? Self.defaultDaysBack, 1), Self.maxDaysBack)
        let cutoff = now.addingTimeInterval(-TimeInterval(days) * 86_400)

        let courseIDs = try await AgentReadTools.courseIDs(for: arguments.course, in: dataSource)
        let announcements = try await AgentReadTools.collect(courseIDs) { try await dataSource.announcements(courseID: $0) }

        return Array(
            announcements
                .filter { ($0.facts.postedAt ?? .distantPast) >= cutoff }
                .sorted { ($0.facts.postedAt ?? .distantPast) > ($1.facts.postedAt ?? .distantPast) }
                .prefix(AgentReadTools.maxResults)
        )
    }
}
