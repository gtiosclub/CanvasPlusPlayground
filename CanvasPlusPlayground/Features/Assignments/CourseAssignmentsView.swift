//
//  CourseAssignmentsView.swift
//  CanvasPlusPlayground
//
//  Created by Sankaet Cheemalamarri on 9/14/24.
//

import SwiftUI

struct CourseAssignmentsView: View {
    let course: Course
    let showGrades: Bool

    @State private var assignmentManager: CourseAssignmentManager
    @State private var gradeCalculator: GradeCalculator

    @State private var isLoadingAssignments = true
    @State private var showingGradeCalculator = false

    init(course: Course, showGrades: Bool = false) {
        self.course = course
        self.showGrades = showGrades

        let manager = CourseAssignmentManager(courseID: course.id)
        _assignmentManager = .init(initialValue: manager)

        _gradeCalculator = .init(
            initialValue: .init(
                assignmentGroups: manager.assignmentGroups
            )
        )
    }

    var body: some View {
        NavigationStack {
            mainbody
        }
    }

    var mainbody: some View {
        List(assignmentManager.assignmentGroups) { assignmentGroup in
            Section {
                let assignments = assignmentGroup.assignments ?? []

                if assignments.isEmpty {
                    Text("No Assignments")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(assignments) { assignment in
                        let assignmentModel = assignment.createModel()
                        AssignmentRow(assignment: assignmentModel, showGrades: showGrades)
                            .contextMenu {
                                if !showGrades {
                                    PinButton(
                                        itemID: assignmentModel.id,
                                        courseID: course.id,
                                        type: .assignment
                                    )
                                }
                            }
                            .swipeActions(edge: .leading) {
                                if !showGrades {
                                    PinButton(
                                        itemID: assignmentModel.id,
                                        courseID: course.id,
                                        type: .assignment
                                    )
                                }
                            }
                    }
                }
            } header: {
                GroupHeader(
                    assignmentGroup: assignmentGroup,
                    showGrades: showGrades
                )
            }
        }
        .toolbar {
            if showGrades {
                ToolbarItem(placement: .automatic) {
                    Button("Calculate Grades") {
                        showingGradeCalculator = true
                    }
                    .disabled(isLoadingAssignments)
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
        .navigationTitle(showGrades ? "Grades" : "Assignments")
        .navigationDestination(for: Assignment.self) { assignment in
            AssignmentDetailView(assignment: assignment)
        }
        .sheet(isPresented: $showingGradeCalculator) {
            NavigationStack {
                GradeCalculatorView()
            }
            .frame(width: 450, height: 600)
            .environment(gradeCalculator)
        }
        .environment(gradeCalculator)
    }

    private func loadAssignments() async {
        isLoadingAssignments = true
        await assignmentManager.fetchAssignmentGroups()
        gradeCalculator.resetGroups(assignmentManager.assignmentGroups)
        isLoadingAssignments = false
    }
}

private struct AssignmentRow: View {
    @Environment(GradeCalculator.self) private var calculator

    let assignment: Assignment
    let showGrades: Bool

    var isDropped: Bool {
        !calculator.gradeGroups
            .flatMap(\.consideredAssignments)
            .map(\.id)
            .contains(assignment.id)
    }

    var body: some View {
        if !showGrades {
            NavigationLink(value: assignment) {
                bodyContents
            }
        } else {
            bodyContents
        }
    }

    private var bodyContents: some View {
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
                if isDropped, !calculator.gradeGroups.isEmpty {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.separator)
                }

                Text(assignment.formattedGrade)
                    .bold()
                +
                Text(" / " + assignment.formattedPointsPossible)
            }
        }
    }
}

private struct GroupHeader: View {
    let assignmentGroup: AssignmentGroup
    let showGrades: Bool

    @State private var showingInfo = false

    private var showsInfoButton: Bool {
        assignmentGroup.rules?.dropLowest != nil ||
        assignmentGroup.rules?.dropHighest != nil ||
        !(assignmentGroup.rules?.neverDrop?.isEmpty ?? true)
    }

    var body: some View {
        HStack {
            Text(assignmentGroup.name)

            Spacer()

            if let groupWeight = assignmentGroup.groupWeight {
                Text(String(format: "%.1f%%", groupWeight))
            } else {
                Text("--%")
            }

            if showGrades, showsInfoButton {
                Button("Show Rules", systemImage: "info.circle") {
                    showingInfo = true
                }
                .popover(isPresented: $showingInfo) {
                    infoGrid
                        .presentationCompactAdaptation(.popover)
                        .presentationBackground(.thinMaterial)
                }
                .buttonStyle(.plain)
                .labelStyle(.iconOnly)
            }
        }
    }

    private var infoGrid: some View {
        VStack {
            Text("Rules").fontWeight(.heavy)

            Spacer()

            Grid {
                if let dropLowest = assignmentGroup.rules?.dropLowest {
                    GridRow {
                        Text("Drop Lowest:")
                            .fontWeight(.light)

                        Spacer()

                        Text(
                            dropLowest,
                            format: .number
                        )
                    }
                }

                if let dropHighest = assignmentGroup.rules?.dropHighest {
                    GridRow {
                        Text("Drop Highest:")
                            .fontWeight(.light)

                        Spacer()

                        Text(
                            dropHighest,
                            format: .number
                        )
                        .bold()
                    }
                }
            }
        }
        .padding(16)
    }
}
