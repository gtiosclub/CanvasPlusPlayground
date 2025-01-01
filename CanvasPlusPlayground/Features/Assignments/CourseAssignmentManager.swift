//
//  CourseAssignmentManager.swift
//  CanvasPlusPlayground
//
//  Created by Sankaet Cheemalamarri on 9/14/24.
//

import SwiftUI

@Observable
class CourseAssignmentManager {
    private let courseID: String?
    var assignments = [AssignmentAPI]()

    init(courseID: String?) {
        self.courseID = courseID
    }

    func fetchAssignments() async {
        guard let courseID = courseID, let (data, _) = try? await CanvasService.shared.fetchResponse(
            CanvasRequest.getAssignments(courseId: courseID)
        ) else {
            print("Failed to fetch assignments.")
            return
        }

        do {
            self.assignments = try JSONDecoder().decode([AssignmentAPI].self, from: data)
        } catch {
            print(error)
        }
    }

    static func getAssignmentsForCourse(courseID: String) async -> [AssignmentAPI] {
            let manager = CourseAssignmentManager(courseID: courseID)
            await manager.fetchAssignments()
            return manager.assignments
    }
}
