//
//  ListCoursesTool.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/8/26.
//

import Foundation
import FoundationModels

/// Lists the student's current courses.
@available(iOS 26.0, macOS 26.0, *)
struct ListCoursesTool: AgentTool {
    @Generable
    struct Arguments {
        @Guide(description: "Optional text to match against the course name or code, like \"1331\" or \"Physics\". Leave empty for all courses.")
        var query: String?
    }

    let name = "listCourses"
    let description = "Lists the student's current courses and their ids. Use a course id from here when another tool asks for one."

    let dataSource: any AgentDataSource

    func evidence(for arguments: Arguments) async throws -> [Evidence] {
        let courses = try await dataSource.courses()
        return Array(AgentReadTools.matchingCourses(courses, query: arguments.query).prefix(AgentReadTools.maxResults))
    }
}
