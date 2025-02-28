//
//  GradeCalculatorView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 2/24/25.
//

import SwiftUI

struct GradeCalculatorView: View {
    @Environment(GradeCalculator.self) private var calculator
    @Environment(\.dismiss) private var dismiss

    @FocusState private var assignmentRowFocus: GradeCalculator.GradeAssignment?
    @FocusState private var groupRowFocus: GradeCalculator.GradeGroup?

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
            .listRowSeparator(.hidden)

            #if os(macOS)
            Divider()
            #endif

            Button("Add Assignment Group", systemImage: "plus.circle.fill") {
                let newGroup = calculator.createEmptyGroup()
                groupRowFocus = newGroup
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .listRowSeparator(.hidden)
        }
        .textFieldStyle(.plain)
        #if os(macOS)
        .listStyle(.sidebar)
        #else
        .listStyle(.inset)
        #endif
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle("Calculate Grades")
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Text("Total: \(calculator.totalGrade.truncatingTrailingZeros)%")
                    .bold()
                    .contentTransition(.numericText())
                    .animation(.default, value: calculator.totalGrade)
            }

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
                }
                .bold()
            }
        }
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
            group.weight / 100.0
        } set: {
            group.weight = $0 * 100.0
        }

        HStack {
            TextField("Assignment Group Name", text: $group.name)
                #if os(macOS)
                .fixedSize()
                #endif

            TextField(
                "Weight",
                value: formattedWeightBinding,
                format: .percent
            )
            .fixedSize()
            .foregroundStyle(.tint)
            #if os(iOS)
            .keyboardType(.numberPad)
            #endif
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
                format: .number
            )
            .pointsTextField()

            Text("/")

            TextField(
                "Total",
                value: $assignment.pointsPossible,
                format: .number
            )
            .pointsTextField()
        }
        .focused($assignmentRowFocus, equals: assignment)
        .draggable(assignment)
        .padding(4)
    }
}

extension View {
    fileprivate func pointsTextField() -> some View {
        self
            .fixedSize()
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundStyle(.tint)
            #if os(iOS)
            .keyboardType(.numberPad)
            #endif
    }
}
