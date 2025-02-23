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
    var assignments = [Assignment]()

    init(courseID: String) {
        self.courseID = courseID
    }

    func fetchAssignments() async {
        let request = CanvasRequest.getAssignments(courseId: courseID)

        do {
            let assignments = try await CanvasService.shared.loadAndSync(
                request,
                onCacheReceive: { cachedAssignments in
                    self.assignments = cachedAssignments ?? []
                }
            )

            self.assignments = assignments
        } catch {
            print("Failed to fetch assignments: \(error)")
        }
    }

    private func setAssignments(_ assignments: [Assignment]) {
        self.assignments = assignments
    }

    static func getAssignmentsForCourse(courseID: String) async -> [Assignment] {
        let manager = CourseAssignmentManager(courseID: courseID)
        await manager.fetchAssignments()
        return manager.assignments
    }
}
