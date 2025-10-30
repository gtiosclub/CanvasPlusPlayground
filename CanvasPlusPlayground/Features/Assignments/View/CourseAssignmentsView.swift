//
//  CourseAssignmentsView.swift
//  CanvasPlusPlayground
//
//  Created by Sankaet Cheemalamarri on 9/14/24.
//

import SwiftUI

struct CourseAssignmentsView: View {
    typealias GroupMode = CourseAssignmentManager.GroupMode
    let course: Course
    /// Display grades in each assignment row. Disables navigation to Assignment Details.
    let showGrades: Bool

    @State private var assignmentManager: CourseAssignmentManager
    @State private var gradeCalculator: GradeCalculator

    @State private var isLoadingAssignments = true
    @State private var showingGradeCalculator = false
    @State private var selectedAssignment: Assignment?

    @SceneStorage("CourseAssignmentsView.currentGroupMode")
    var currentGroupMode: GroupMode = .type

    var displayedAssignmentGroups: [any AssignmentGroupCategory] {
        switch currentGroupMode {
        case .type:
            assignmentManager.assignmentGroups
        case .dueDate:
            [
                UpcomingAssignmentsCategory(
                    allAssignments: assignmentManager.allAssignments
                ),
                PastAssignmentsCategory(
                    allAssignments: assignmentManager.allAssignments
                )
            ]
        }
    }

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
        mainbody
            #if os(iOS)
            .onAppear {
                selectedAssignment = nil
            }
            #endif
    }

    var mainbody: some View {
        List(
            displayedAssignmentGroups,
            id: \.id,
            selection: $selectedAssignment
        ) { assignmentGroup in
            Section {
                let assignments = assignmentGroup.assignments ?? []

                if assignments.isEmpty {
                    Text("No Assignments")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(assignments) { assignment in
                        let assignmentModel = assignment.createModel()
                        AssignmentRow(assignment: assignmentModel, showGrades: showGrades)
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
            ToolbarItem {
                Menu {
                    groupByPicker
                } label: {
                    Label("Group By...", systemImage: "arrow.up.arrow.down")
                }
            }

            if showGrades {
                ToolbarItem(placement: .automatic) {
                    Button("Calculate Grades", image: .customFunctionCapsule) {
                        showingGradeCalculator = true
                    }
                    #if os(macOS)
                    .labelStyle(.titleAndIcon)
                    #endif
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
        #if os(iOS)
        .navigationTitle(showGrades ? "Grades" : "Assignments")
        #else
        .navigationTitle(showGrades ? "\(course.displayName) -- Grades" : "\(course.displayName) -- Assignments")
        #endif
        .sheet(isPresented: $showingGradeCalculator) {
            NavigationStack {
                GradeCalculatorView(
                    course: course,
                    assignmentGroups: assignmentManager.assignmentGroups
                )
            }
            #if os(macOS)
            .frame(width: 650, height: 550)
            #endif
        }
        .environment(gradeCalculator)
    }

    private var groupByPicker: some View {
        Picker("Group Assignments",
            selection: $currentGroupMode) {
                ForEach(GroupMode.allCases,id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .fixedSize()
            .pickerStyle(.inline)
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
    @Environment(\.openURL) private var openURL
    @Environment(PinnedItemsManager.self) private var pinnedItemsManager
    let assignment: Assignment
    let showGrades: Bool

    var isDropped: Bool {
        !calculator.gradeGroups
            .flatMap(\.consideredAssignments)
            .map(\.id)
            .contains(assignment.id)
    }

    var isPinned: Bool {
        pinnedItemsManager.pinnedItems.contains {
            $0.id == assignment.id && $0.courseID == assignment.courseId?.asString && $0.type == .assignment
        }
    }

    var body: some View {
        if !showGrades {
            NavigationLink(
                value: NavigationModel.Destination.assignment(assignment)
            ) {
                bodyContents
            }
            .contextMenu {
                PinButton(
                    itemID: assignment.id,
                    courseID: assignment.courseId?.asString,
                    type: .assignment
                )
                NewWindowButton(destination: .assignment(assignment))
                OpenInCanvasButton(path: .assignment(assignment.courseId?.asString ?? "MISSING_COURSE_ID", assignment.id))
            }
            .swipeActions(edge: .leading) {
                PinButton(
                    itemID: assignment.id,
                    courseID: assignment.courseId?.asString,
                    type: .assignment
                )
            }
            .tag(assignment)
        } else {
            bodyContents
        }
    }

    private var bodyContents: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(assignment.name)
                        .fontWeight(.bold)
                        .pinnedItemBadge(isVisible: isPinned)
                }

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
    let assignmentGroup: any AssignmentGroupCategory
    let showGrades: Bool

    @State private var showingInfo = false

    private var showsInfoButton: Bool {
        assignmentGroup.rules?.dropLowest != nil ||
        assignmentGroup.rules?.dropHighest != nil ||
        !(assignmentGroup.rules?.neverDrop?.isEmpty ?? true)
    }

    var body: some View {
        HStack {
            Text(assignmentGroup.title)

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
