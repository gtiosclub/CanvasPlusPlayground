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
            let submission = assignment.submission?.createModel()

            HStack {
                VStack(alignment: .leading) {
                    Text(assignment.name)
                        .font(.headline)
                    Group {
                        if let submission {
                            Text(
                                submission.workflowState?.rawValue.capitalized ?? "Unknown Status"
                            )
                        }
                    }
                    .font(.subheadline)
                }

                if showGrades, let submission {
                    Spacer()

                    Text(submission.score?.truncatingTrailingZeros ?? "--") +
                    Text("/") +
                    Text(assignment.points_possible?.truncatingTrailingZeros ?? "--")
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
