//
//  CourseAssignmentManager.swift
//  CanvasPlusPlayground
//
//  Created by Sankaet Cheemalamarri on 9/14/24.
//

import SwiftUI

@Observable
class CourseAssignmentManager {
    private let courseID: String
    var assignmentGroups = [AssignmentGroup]()

    init(courseID: String) {
        self.courseID = courseID
    }

    func fetchAssignments() async -> [Assignment] {
        let request = CanvasRequest.getAssignments(courseId: courseID)

        do {
            let assignments = try await CanvasService.shared.loadAndSync(request)

            return assignments
        } catch {
            print("Failed to fetch assignments: \(error)")
        }

        return []
    }

    func fetchAssignmentGroups() async {
        let request = CanvasRequest.getAssignmentGroups(courseId: courseID)

        do {
            let groups = try await CanvasService.shared.loadAndSync(
                request,
                onCacheReceive: { cachedGroups in
                    self.assignmentGroups = cachedGroups ?? []
                }
            )

            self.assignmentGroups = groups
        } catch {
            print("Failed to fetch assignment groups")
        }
    }

    static func getAssignmentsForCourse(courseID: String) async -> [Assignment] {
        let manager = CourseAssignmentManager(courseID: courseID)
        return await manager.fetchAssignments()
    }
}
