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
        NavigationStack {
            mainbody
        }
    }
    var mainbody: some View {
        List(assignmentManager.assignments) { assignment in
            AssignmentRow(assignment: assignment, showGrades: showGrades)
                .contextMenu {
                    PinButton(
                        itemID: assignment.id,
                        courseID: course.id,
                        type: .assignment
                    )
                }
                .swipeActions(edge: .leading) {
                    PinButton(
                        itemID: assignment.id,
                        courseID: course.id,
                        type: .assignment
                    )
                }
        }
        .task {
            await loadAssignments()
        }
        .refreshable {
            await loadAssignments()
        }
        .statusToolbarItem("Assignments", isVisible: isLoadingAssignments)
        .navigationTitle(course.displayName)
        .navigationDestination(for: Assignment.self) { assignment in
            AssignmentDetailView(assignment: assignment)
        }
    }

    private func loadAssignments() async {
        isLoadingAssignments = true
        await assignmentManager.fetchAssignments()
        isLoadingAssignments = false
    }
}

struct AssignmentRow: View {
    let assignment: Assignment
    let showGrades: Bool

    var body: some View {
        NavigationLink(value: assignment) {
            HStack {
                Text(assignment.name)
                    .font(.headline)
            }
        }
    }
}
