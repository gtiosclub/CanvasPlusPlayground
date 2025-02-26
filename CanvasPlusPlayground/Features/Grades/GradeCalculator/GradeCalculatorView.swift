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

    var body: some View {
        @Bindable var calculator = calculator

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

    private func groupHeader(for group: GradeCalculator.GradeGroup) -> some View {
        HStack {
            Text(group.name)
            Spacer()
            Text("\(group.weight.truncatingTrailingZeros)%")
        }
        .bold()
        .padding(4)
    }

    private func assignmentRow(for assignment: Binding<GradeCalculator.GradeAssignment>) -> some View {
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
        for group: GradeCalculator.GradeGroup
    ) -> Binding<Bool> {
        .init {
            calculator.expandedAssignmentGroups[group, default: true]
        } set: { newValue in
            calculator.expandedAssignmentGroups[group] = newValue
        }
    }
}
