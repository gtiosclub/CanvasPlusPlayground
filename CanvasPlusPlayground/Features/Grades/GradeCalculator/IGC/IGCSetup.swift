//
//  IGCSetup.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/24/25.
//

import SwiftUI

@Observable
class IGCSetupManager {
    static let extractedGroupsKey = "IGCSetupManager.extractedGroups"

    var course: Course?
    var calculator: GradeCalculator?
    var pickedItem: (any PickableItem)?

    /// The grade groups extracted by intelligence.
    var extractedGroups: [GradeCalculator.GradeGroup]?

    var previouslyExtractedWeightsAvailable: Bool {
        UserDefaults.standard.value(forKey: Self.extractedGroupsKey) != nil
    }

    func usePreviouslyExtractedWeights() {
        guard let data = UserDefaults.standard.data(forKey: Self.extractedGroupsKey) else {
            return
        }

        if let decoded = try? JSONDecoder().decode(
            [GradeCalculator.GradeGroup].self,
            from: data
        ) {
            extractedGroups = decoded
        }
    }

    /// Transfers the intelligence-extracted weights to the grade calculator, replacing the grade
    /// calculator's existing grade groups.
    func transferExtractedGroups() {
        guard let calculator, let extractedGroups, !extractedGroups.isEmpty else {
            return
        }

        var newAssignmentGroups = extractedGroups

        // If existing groups retrieved from user defaults already has 'uncategorized',
        // use that.
        var uncategorizedAssignmentGroup = extractedGroups.first { $0.id == "uncategorized" } ?? GradeCalculator.GradeGroup.init(
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

        var uncategorizedAssignments = Set<GradeCalculator.GradeAssignment>()
        for oldGroup in calculator.gradeGroups {
            if !oldGroup.assignments.isEmpty {
                uncategorizedAssignments = uncategorizedAssignments
                    .union(oldGroup.assignments)
            }
        }

        uncategorizedAssignmentGroup.assignments = Array(
            uncategorizedAssignments
        )

        if !newAssignmentGroups.contains(where: { $0.id == "uncategorized" }) {
            newAssignmentGroups.append(uncategorizedAssignmentGroup)
        }

        do {
            let data = try JSONEncoder().encode(newAssignmentGroups)
            UserDefaults.standard.set(data, forKey: Self.extractedGroupsKey)
        } catch {
            LoggerService.main.error(
                "Failed to encode extractedGroups to UserDefaults: \(error)"
            )
        }

        calculator.gradeGroups = newAssignmentGroups
    }
}

/// Entry point for setting up the Intelligent Grade Calculator.
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
                .navigationDestination(for: IGCOnboardingScreen.self) { screen in
                    IGCOnboardingView(screen: screen, path: $path, dismiss: dismiss)
                }
        }
        .onAppear {
            manager.course = course
            manager.calculator = calculator
        }
        .environment(manager)
    }
}
