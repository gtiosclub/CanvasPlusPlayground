//
//  GradeCalculatorView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 2/24/25.
//

import SwiftUI

struct GradeCalculatorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var calculator: GradeCalculator

    @FocusState private var assignmentRowFocus: GradeCalculator.GradeAssignment?
    @FocusState private var groupRowFocus: GradeCalculator.GradeGroup?

    init(assignmentGroups: [AssignmentGroup]) {
        _calculator = .init(
            initialValue: .init(assignmentGroups: assignmentGroups)
        )
    }

    var body: some View {
        @Bindable var calculator = calculator

        List {
            ForEach($calculator.gradeGroups, id: \.id) { $group in
                GradeGroupSection(
                    group: $group,
                    assignmentRowFocus: _assignmentRowFocus,
                    groupRowFocus: _groupRowFocus
                )
            }
            .onMove {
                calculator.gradeGroups.move(fromOffsets: $0, toOffset: $1)
            }

            Button("Add Assignment Group", systemImage: "plus.circle.fill") {
                let newGroup = calculator.createEmptyGroup()
                groupRowFocus = newGroup
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
        .navigationTitle("Calculate Grades")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top) {
            totalGradeView
        }
        #endif
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .destructiveAction) {
                totalGradeView
            }
            #endif

            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    #if os(macOS)
                    Text("Done")
                    #else
                    Image(systemName: "xmark")
                    #endif
                }
                .keyboardShortcut(
                    assignmentRowFocus == nil && groupRowFocus == nil ? .defaultAction : .none
                )
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    assignmentRowFocus = nil
                    groupRowFocus = nil
                }
                .bold()
            }
        }
        .environment(calculator)
    }

    private var totalGradeView: some View {
        #if os(iOS)
        AccessoryBar(title: "Total", value: "\(calculator.totalGrade.truncatingTrailingZeros)%")
            .animation(.default, value: calculator.totalGrade)
        #else
        Text("Total: \(calculator.totalGrade.truncatingTrailingZeros)%")
            .bold()
            .contentTransition(.numericText())
            .animation(.default, value: calculator.totalGrade)
        #endif
    }
}

private struct GradeGroupSection: View {
    @Environment(GradeCalculator.self) private var calculator
    @Binding var group: GradeCalculator.GradeGroup
    @FocusState var assignmentRowFocus: GradeCalculator.GradeAssignment?
    @FocusState var groupRowFocus: GradeCalculator.GradeGroup?

    var body: some View {
        DisclosureGroup(isExpanded: isExpanded) {
            ForEach($group.assignments, id: \.id) { $assignment in
                GradeAssignmentRow(assignment: $assignment, assignmentRowFocus: _assignmentRowFocus)
            }
            .onMove {
                group.assignments.move(fromOffsets: $0, toOffset: $1)
            }
            .onDelete {
                group.assignments.remove(atOffsets: $0)
            }

            addAssignmentButton
        } label: {
            GradeGroupHeader(group: $group, groupRowFocus: _groupRowFocus)
        }
        .dropDestination(for: GradeCalculator.GradeAssignment.self) { assignments, _ in
            calculator.moveAssignments(assignments, to: group)
        }
    }

    private var addAssignmentButton: some View {
        Button("Add Assignment", systemImage: "plus.circle.fill") {
            let newAssignment = calculator.createEmptyAssignment(in: group)
            assignmentRowFocus = newAssignment
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .padding(4)
    }

    private var isExpanded: Binding<Bool> {
        .init {
            calculator.expandedAssignmentGroups[group, default: true]
        } set: { newValue in
            calculator.expandedAssignmentGroups[group] = newValue
        }
    }
}

private struct GradeGroupHeader: View {
    @Binding var group: GradeCalculator.GradeGroup
    @FocusState var groupRowFocus: GradeCalculator.GradeGroup?

    var body: some View {
        let formattedWeightBinding: Binding<Double> = .init {
            group.weight
        } set: {
            group.weight = $0
        }

        HStack {
            TextField("Assignment Group Name", text: $group.name)
                #if os(macOS)
                .fixedSize()
                #endif

            HStack(spacing: 0) {
                TextField(
                    "--",
                    value: formattedWeightBinding,
                    format: .number
                )
                .fixedSize()
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif

                Text("%")
            }
            .foregroundStyle(.tint)
        }
        .bold()
        .padding(4)
        .focused($groupRowFocus, equals: group)
        .foregroundStyle(group.weightedScore == nil ? .secondary : .primary)
    }
}

private struct GradeAssignmentRow: View {
    @Binding var assignment: GradeCalculator.GradeAssignment
    @FocusState var assignmentRowFocus: GradeCalculator.GradeAssignment?

    var body: some View {
        HStack {
            TextField(
                "Assignment Name",
                text: $assignment.name,
                prompt: Text("Assignment Name")
            )

            Spacer()

            TextField(
                "Score",
                value: $assignment.pointsEarned,
                format: .number,
                prompt: Text("--")
            )
            .pointsTextField()

            Text("/")

            TextField(
                "Total",
                value: $assignment.pointsPossible,
                format: .number,
                prompt: Text("--")
            )
            .pointsTextField()
        }
        .focused($assignmentRowFocus, equals: assignment)
        .draggable(assignment)
        .padding(4)
    }
}

extension TextField {
    fileprivate func pointsTextField() -> some View {
        self
            .fixedSize()
            .multilineTextAlignment(.trailing)
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundStyle(.tint)
            #if os(iOS)
            .keyboardType(.numberPad)
            #endif
    }
}
