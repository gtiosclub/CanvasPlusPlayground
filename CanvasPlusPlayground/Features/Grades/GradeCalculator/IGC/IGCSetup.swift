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
    
    /// Backing storage for extractedGroups loaded from UserDefaults.
    private var _extractedGroups: [GradeCalculator.GradeGroup]?

    /// The grade groups extracted by intelligence.
    var extractedGroups: [GradeCalculator.GradeGroup]? {
        get {
            if _extractedGroups == nil {
                // Attempt to load from UserDefaults on first access
                if let data = UserDefaults.standard.data(forKey: "IGCSetupManager.extractedGroups") {
                    do {
                        _extractedGroups = try JSONDecoder().decode([GradeCalculator.GradeGroup].self, from: data)
                    } catch {
                        LoggerService.main.error(
                            "Failed to decode extractedGroups from UserDefaults: \(error)"
                        )
                    }
                }
            }
            return _extractedGroups
        }
        set {
            _extractedGroups = newValue
            guard let groups = newValue else {
                UserDefaults.standard.removeObject(forKey: "IGCSetupManager.extractedGroups")
                return
            }
            do {
                let data = try JSONEncoder().encode(groups)
                UserDefaults.standard.set(data, forKey: "IGCSetupManager.extractedGroups")
            } catch {
                LoggerService.main.error("Failed to encode extractedGroups to UserDefaults: \(error)")
            }
        }
    }

    /// Transfers the intelligence-extracted weights to the grade calculator, replacing the grade
    /// calculator's existing grade groups.
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
        }
        .onAppear {
            manager.course = course
            manager.calculator = calculator
        }
        .environment(manager)
    }
}
