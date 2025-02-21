//
//  AggregatedAssignmentsViewModel.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/23/24.
//

import Foundation
import SwiftUI

@Observable
class AggregatedAssignmentsViewModel {
    var assignments: [(Assignment, Course)] = []

    func loadAssignments(courses: [Course]) async {
        for course in courses {
            let newAssignments = await CourseAssignmentManager.getAssignmentsForCourse(courseID: course.id)

            for assignment in newAssignments where assignment.submission?.workflow_state == .unsubmitted {
                // we only want to show assignments w/o submissions
                self.assignments.append((assignment, course))
            }
        }
    }
}
