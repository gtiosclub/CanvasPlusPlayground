//
//  CourseAssignmentView.swift
//  CanvasPlusPlayground
//
//  Created by Sankaet Cheemalamarri on 9/14/24.
//

import SwiftUI

struct CourseAssignmentsView: View {
    let course: Course
    let showGrades: Bool
    @State private var assignmentManager: CourseAssignmentManager

    @State private var isLoadingAssignments = true

    init(course: Course, showGrades: Bool = false) {
        self.course = course
        self.showGrades = showGrades
        _assignmentManager = .init(initialValue: CourseAssignmentManager(courseID: course.id))
    }

    var body: some View {
        List(assignmentManager.assignments, id: \.id) { assignment in
            HStack {
                VStack(alignment: .leading) {
                    Text(assignment.name ?? "")
                        .font(.headline)
                    Group {
                        if let submission = assignment.submission {
                            Text("Submitted")
                        } else {
                            Text("Not Submitted")
                        }
                    }
                    .font(.subheadline)
                }

                if showGrades, let submission = assignment.submission {
                    Spacer()

                    Text(submission.score?.truncatingTrailingZeros ?? "--") +
                    Text("/") +
                    Text(assignment.pointsPossible?.truncatingTrailingZeros ?? "--")
                }
            }
        }
        .task {
            await loadAssignments()
        }
        .statusToolbarItem("Assignments", isVisible: isLoadingAssignments)
        .navigationTitle(course.displayName)
    }

    private func loadAssignments() async {
        isLoadingAssignments = true
        await assignmentManager.fetchAssignments()
        isLoadingAssignments = false
    }
}
