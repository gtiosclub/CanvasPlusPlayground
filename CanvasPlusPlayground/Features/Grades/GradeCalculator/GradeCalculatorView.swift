//
//  GradeCalculatorView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/5/25.
//

import SwiftUI

struct GradeCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var gradeCalculator: CourseGradeCalculatorBridge

    @FocusState private var assignmentRowFocus: CourseGradeCalculator.GradeCalculatorAssignment?

    init(assignmentGroups: [AssignmentGroupAPI]) {
        _gradeCalculator = .init(
            initialValue: CourseGradeCalculatorBridge(from: assignmentGroups)
        )
    }

    var body: some View {
        List($gradeCalculator.assignmentGroups, id: \.id) { $group in
            DisclosureGroup(
                isExpanded: isExpanded(for: group)
            ) {
                ForEach($group.assignments, id: \.id) { $assignment in
                    assignmentRow(for: $assignment)
                }
            } label: {
                groupHeader(for: group)
            }
        }
        #if os(macOS)
        .frame(width: 600, height: 400)
        #endif
        .navigationTitle("Calculate Grades")
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Text("Total: \(gradeCalculator.finalGrade)")
                    .contentTransition(.numericText())
                    .animation(.default, value: gradeCalculator.finalGrade)
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

    private func groupHeader(for group: CourseGradeCalculatorBridge.GradeCalculatorAssignmentGroup) -> some View {
        HStack {
            Text(group.name)
            Spacer()
            Text("\(group.displayWeight)")
        }
        .bold()
        .padding(4)
    }

    private func assignmentRow(for assignment: Binding<CourseGradeCalculator.GradeCalculatorAssignment>) -> some View {
        HStack {
            Text(assignment.wrappedValue.name)

            Spacer()

            TextField(
                "Score",
                value: assignment.score,
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
        for group: CourseGradeCalculatorBridge.GradeCalculatorAssignmentGroup
    ) -> Binding<Bool> {
        .init {
            gradeCalculator.expandedAssignmentGroups[group, default: true]
        } set: { newValue in
            gradeCalculator.expandedAssignmentGroups[group] = newValue
        }
    }
}
