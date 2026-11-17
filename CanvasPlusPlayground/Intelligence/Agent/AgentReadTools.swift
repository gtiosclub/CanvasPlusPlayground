//
//  AgentReadTools.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/8/26.
//

import Foundation

/// Shared helpers for the read tools.
enum AgentReadTools {
    /// Caps every tool's output so a few tool calls fit in the on-device context window.
    static let maxResults = 10

    /// Courses whose id, name or code match `query`. A missing or empty query matches all of them.
    static func matchingCourses(_ courses: [Evidence], query: String?) -> [Evidence] {
        let query = (query ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return courses }

        return courses.filter { course in
            course.ref.recordID == query
                || course.title.localizedCaseInsensitiveContains(query)
                || course.snippet.localizedCaseInsensitiveContains(query)
        }
    }

    /// The course ids a tool should search. The model sometimes passes a course name
    /// instead of an id, so both are accepted. An unknown course gives no ids (and so no results).
    static func courseIDs(for course: String?, in dataSource: any AgentDataSource) async throws -> [String] {
        let courses = try await dataSource.courses()
        let trimmed = (course ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmed.isEmpty, courses.contains(where: { $0.ref.recordID == trimmed }) {
            return [trimmed]
        }

        return matchingCourses(courses, query: trimmed).map(\.ref.recordID)
    }

    /// Runs `load` for every course and merges the results. A course that fails to load is
    /// skipped so one bad course doesn't hide the rest; if every course fails, the first error is thrown.
    static func collect(
        _ courseIDs: [String],
        load: (String) async throws -> [Evidence]
    ) async throws -> [Evidence] {
        var results: [Evidence] = []
        var firstError: Error?
        var failures = 0

        for courseID in courseIDs {
            do {
                results += try await load(courseID)
            } catch {
                failures += 1
                firstError = firstError ?? error
            }
        }

        if let firstError, failures == courseIDs.count {
            throw firstError
        }

        return results
    }
}
