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
        List(assignmentManager.assignmentGroups) { assignmentGroup in
            Section {
                ForEach(assignmentGroup.assignments ?? []) { assignment in
                    AssignmentRow(assignment: assignment, showGrades: showGrades)
                }
            } header: {
                HStack {
                    Text(assignmentGroup.name ?? "")

                    Spacer()

                    if let groupWeight = assignmentGroup.groupWeight {
                        Text("\(groupWeight)%")
                    }
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
        await assignmentManager.fetchAssignmentGroups()
        isLoadingAssignments = false
    }
}

private struct AssignmentRow: View {
    let assignment: Assignment
    let showGrades: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(assignment.name ?? "")
                    .font(.headline)
                Group {
                    if let submission = assignment.submission {
                        Text(
                            submission.workflowState?.rawValue.capitalized ?? "Unknown Status"
                        )
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
}
