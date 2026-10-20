//
//  ListAssignmentsTool.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/8/26.
//

import Foundation
import FoundationModels

/// Lists assignments, soonest due first.
@available(iOS 26.0, macOS 26.0, *)
struct ListAssignmentsTool: AgentTool {
    @Generable
    struct Arguments {
        @Guide(description: "A course id or name from listCourses. Leave empty to search every course.")
        var course: String?

        @Guide(description: "Only include assignments due within this many days from now. Leave empty for everything upcoming.")
        var daysAhead: Int?

        @Guide(description: "Set to true to also include assignments whose due date has already passed.")
        var includePastDue: Bool?
    }

    let name = "listAssignments"
    let description = "Lists assignments with their due dates, points and scores, soonest due first."

    let dataSource: any AgentDataSource
    var now: @Sendable () -> Date = { .now }

    func evidence(for arguments: Arguments) async throws -> [Evidence] {
        let now = now()
        let courseIDs = try await AgentReadTools.courseIDs(for: arguments.course, in: dataSource)
        let assignments = try await AgentReadTools.collect(courseIDs) { try await dataSource.assignments(courseID: $0) }

        let horizon = arguments.daysAhead.map { now.addingTimeInterval(TimeInterval(max($0, 0)) * 86_400) }
        let includePastDue = arguments.includePastDue ?? false

        var upcoming: [Evidence] = []
        var pastDue: [Evidence] = []
        var undated: [Evidence] = []

        for assignment in assignments {
            guard let dueDate = assignment.facts.dueDate else {
                // Undated work only makes sense when the caller isn't asking about a time window.
                if horizon == nil { undated.append(assignment) }
                continue
            }

            if dueDate < now {
                if includePastDue { pastDue.append(assignment) }
            } else if horizon.map({ dueDate <= $0 }) ?? true {
                upcoming.append(assignment)
            }
        }

        upcoming.sort { ($0.facts.dueDate ?? .distantFuture) < ($1.facts.dueDate ?? .distantFuture) }
        // Most recently missed first, so the cap keeps the ones that still matter.
        pastDue.sort { ($0.facts.dueDate ?? .distantPast) > ($1.facts.dueDate ?? .distantPast) }

        return Array((upcoming + pastDue + undated).prefix(AgentReadTools.maxResults))
    }
}
