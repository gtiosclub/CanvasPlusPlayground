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
    var assignmentGroups: [AssignmentGroup] = []

    init(courseID: String?) {
        self.courseID = courseID
    }

    func fetchAssignmentGroups() async {
        guard let courseID = courseID, let (data, _) = try? await CanvasService.shared.fetchResponse(
            CanvasRequest.getAssignmentGroups(courseId: courseID)
        ) else {
            print("Failed to fetch assignment groups.")
            return
        }
        
        self.assignmentGroups = (try? JSONDecoder().decode([AssignmentGroup].self, from: data)) ?? []
    }

    static func getAssignmentsForCourse(courseID: String) async -> [Assignment] {
        await CourseAssignmentManager.fetchAssignments(courseID: courseID)
    }

    private static func fetchAssignments(courseID: String) async -> [Assignment] {
        guard let (data, _) = try? await CanvasService.shared.fetchResponse(CanvasRequest.getAssignments(courseId: courseID)) else {
            print("Failed to fetch assignments.")
            return []
        }

        do {
            return try JSONDecoder().decode([Assignment].self, from: data)
        } catch {
            print(error)
        }

        return []
    }
}
