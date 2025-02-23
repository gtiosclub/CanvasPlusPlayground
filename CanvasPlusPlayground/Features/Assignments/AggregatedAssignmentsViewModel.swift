//
//  AggregatedAssignmentsViewModel.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/23/24.
//

import Foundation
import SwiftUI

public class AggregatedAssignmentsViewModel: ObservableObject {
    let courses: [Course]
    @Published var assignments: [(Assignment, Course)] = []

    init(courses: [Course]) {
        self.courses = courses
    }

    func loadAssignments() async {
        for course in courses {
            let newAssignments = await CourseAssignmentManager.getAssignmentsForCourse(courseID: course.id)

            for assignment in newAssignments where !(
                assignment.hasSubmittedSubmissions ?? false
            ) {
                // we only want to show assignments w/o submissions
                self.assignments.append((assignment, course))
            }
        }
    }
}
