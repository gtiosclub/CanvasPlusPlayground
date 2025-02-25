//
//  GradeCalculatorView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 2/24/25.
//

import SwiftUI

struct GradeCalculatorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var calculator: GradeCalculatorViewModel
    @FocusState private var assignmentRowFocus: GradeCalculatorViewModel.GradeAssignment?

    init(assignmentGroups: [AssignmentGroup]) {
        self._calculator = .init(
            initialValue: .init(assignmentGroups: assignmentGroups)
        )
    }

    var body: some View {
        List {
            ForEach($calculator.gradeGroups, id: \.id) { $group in
                DisclosureGroup(
                    isExpanded: isExpanded(for: group)
                ) {
                    ForEach($group.assignments, id: \.id) { $assignment in
                        assignmentRow(for: $assignment)
                    }
                    .onMove {
                        group.assignments.move(fromOffsets: $0, toOffset: $1)
                    }
                } label: {
                    groupHeader(for: group)
                }
            }
            .onMove {
                calculator.gradeGroups.move(fromOffsets: $0, toOffset: $1)
            }
        }
        .navigationTitle("Calculate Grades")
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Text("Total: \(calculator.totalGrade)")
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
                .keyboardShortcut(assignmentRowFocus == nil ? .defaultAction : .none)
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

    private func groupHeader(for group: GradeCalculatorViewModel.GradeGroup) -> some View {
        HStack {
            Text(group.name)
            Spacer()
            Text("\(group.weight.truncatingTrailingZeros)%")
        }
        .bold()
        .padding(4)
    }

    private func assignmentRow(for assignment: Binding<GradeCalculatorViewModel.GradeAssignment>) -> some View {
        HStack {
            Text(assignment.wrappedValue.name)

            Spacer()

            TextField(
                "Score",
                value: assignment.pointsEarned,
                format: .number
            )
                .focused($assignmentRowFocus, equals: assignment.wrappedValue)
                .fixedSize()
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.tint)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif

            Text(
                " / " +
                "\(assignment.wrappedValue.pointsPossible?.truncatingTrailingZeros ?? "-")"
            )
        }
        .padding(.vertical, 4)
    }

    private func isExpanded(
        for group: GradeCalculatorViewModel.GradeGroup
    ) -> Binding<Bool> {
        .init {
            calculator.expandedAssignmentGroups[group, default: true]
        } set: { newValue in
            calculator.expandedAssignmentGroups[group] = newValue
        }
    }
}
