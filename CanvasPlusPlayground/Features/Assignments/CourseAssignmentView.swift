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
        List(assignmentManager.assignmentGroups) { assignmentGroup in
            Section {
                ForEach(assignmentGroup.assignments ?? []) { assignment in
                    let assignmentModel = assignment.createModel()
                    AssignmentRow(assignment: assignmentModel, showGrades: showGrades)
                        .contextMenu {
                            PinButton(
                                itemID: assignmentModel.id,
                                courseID: course.id,
                                type: .assignment
                            )
                        }
                        .swipeActions(edge: .leading) {
                            PinButton(
                                itemID: assignmentModel.id,
                                courseID: course.id,
                                type: .assignment
                            )
                        }
                }
            } header: {
                HStack {
                    Text(assignmentGroup.name)
                    Spacer()
                    if let groupWeight = assignmentGroup.groupWeight {
                        Text(String(format: "%.1f%%", groupWeight))
                    } else {
                        Text("--%")
                    }
                }
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
        await assignmentManager.fetchAssignmentGroups()
        isLoadingAssignments = false
    }
}

struct AssignmentRow: View {
    let assignment: Assignment
    let showGrades: Bool

    var body: some View {
        NavigationLink(value: assignment) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(assignment.name)
                        .fontWeight(.bold)

                    if assignment.isLocked, let unlockDate = assignment.unlockDate {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")

                            Text("Available ")
                                .fontWeight(.semibold)
                            +
                            Text(unlockDate, style: .date)
                        }
                    } else if let dueDate = assignment.dueDate {
                        Text("Due ")
                            .fontWeight(.semibold)
                        +
                        Text(dueDate, style: .date)
                    }
                }
                .fontWeight(.light)

                Spacer()

                if showGrades {
                    Text(assignment.formattedGrade)
                        .bold()
                    +
                    Text(" / " + assignment.formattedPointsPossible)
                }
            }
        }
    }
}
