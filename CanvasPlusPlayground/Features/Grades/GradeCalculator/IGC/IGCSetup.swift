//
//  IGCSetup.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/24/25.
//

import SwiftUI

@Observable
class IGCSetupManager {
    var course: Course?
    var calculator: GradeCalculator?
    var pickedItem: (any PickableItem)?
    var extractedGroups: [GradeCalculator.GradeGroup]?

    func transferExtractedGroups() {
        guard let calculator, let extractedGroups, !extractedGroups.isEmpty else {
            return
        }

        var newAssignmentGroups = extractedGroups

        var uncategorizedAssignments = GradeCalculator.GradeGroup.init(
            id: "uncategorized",
            name: "Uncategorized",
            weight: 0.0
        )

        for var group in newAssignmentGroups {
            let oldGroup = calculator.gradeGroups.firstIndex { $0.id == group.id }
            if let oldGroup {
                group.assignments = calculator.gradeGroups[oldGroup].assignments
                calculator.gradeGroups[oldGroup].assignments.removeAll()
            }
        }

        for oldGroup in calculator.gradeGroups {
            if !oldGroup.assignments.isEmpty {
                uncategorizedAssignments.assignments
                    .append(contentsOf: oldGroup.assignments)
            }
        }

        newAssignmentGroups.append(uncategorizedAssignments)

        calculator.gradeGroups = newAssignmentGroups
    }
}

@available(macOS 26.0, iOS 26.0, *)
struct IGCSetup: View {
    @Environment(\.dismiss) var dismiss

    let course: Course
    let calculator: GradeCalculator
    @State private var path = [IGCOnboardingScreen]()
    @State private var manager = IGCSetupManager()

    var body: some View {
        NavigationStack(path: $path) {
            IGCOnboardingView(
                screen: IGCOnboardingScreen.first,
                path: $path,
                dismiss: dismiss)
                .toolbar {
                    Button(role: .close) { dismiss() }
                }
        }
        .onAppear {
            manager.course = course
            manager.calculator = calculator
        }
        .environment(manager)
    }
}

@available(macOS 26.0, iOS 26.0, *)
#Preview {
    IGCSetup(course: .sample, calculator: .init(assignmentGroups: []))
}
