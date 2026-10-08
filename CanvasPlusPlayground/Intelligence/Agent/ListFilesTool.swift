//
//  ListFilesTool.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/8/26.
//

import Foundation
import FoundationModels

/// Lists course files, optionally filtered by name.
@available(iOS 26.0, macOS 26.0, *)
struct ListFilesTool: AgentTool {
    @Generable
    struct Arguments {
        @Guide(description: "A course id or name from listCourses. Leave empty to search every course.")
        var course: String?

        @Guide(description: "Optional text to match against the file name, like \"syllabus\" or \"lecture 5\".")
        var query: String?
    }

    let name = "listFiles"
    let description = "Lists course files by name, most recently updated first. Use query to find a specific file."

    let dataSource: any AgentDataSource

    func evidence(for arguments: Arguments) async throws -> [Evidence] {
        let query = (arguments.query ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        let courseIDs = try await AgentReadTools.courseIDs(for: arguments.course, in: dataSource)
        let files = try await AgentReadTools.collect(courseIDs) { try await dataSource.files(courseID: $0) }

        return Array(
            files
                .filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) }
                .sorted { ($0.facts.postedAt ?? .distantPast) > ($1.facts.postedAt ?? .distantPast) }
                .prefix(AgentReadTools.maxResults)
        )
    }
}
