//
//  CourseAssignmentView.swift
//  CanvasPlusPlayground
//
//  Created by Sankaet Cheemalamarri on 9/14/24.
//

import SwiftUI

struct CourseAssignmentsView: View {
    let course: Course
    @State private var assignmentManager: CourseAssignmentManager

    init(course: Course) {
        self.course = course
        _assignmentManager = .init(initialValue: CourseAssignmentManager(courseID: course.id))
    }

    var body: some View {
        List(assignmentManager.assignments, id: \.id) { assignment in
            VStack(alignment: .leading) {
                Text(assignment.name ?? "")
                    .font(.headline)
                if let submitted = assignment.hasSubmittedSubmissions {
                    Text(submitted ? "Submitted" : "Not submitted")
                        .font(.subheadline)
                }
            }
        }
        .task {
            await assignmentManager.fetchAssignments()
        }
        .navigationTitle(course.name ?? "")
    }
}
