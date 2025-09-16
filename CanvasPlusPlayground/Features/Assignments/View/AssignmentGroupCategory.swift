//
//  AssignmentGroupCategory.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/11/25.
//

import Foundation

protocol AssignmentGroupCategory: Identifiable {
    var id: String { get }
    var title: String { get }
    var assignments: [AssignmentAPI]? { get }
    var rules: AssignmentGroupRules? { get }
    var groupWeight: Double? { get }
}

struct UpcomingAssignmentsCategory: AssignmentGroupCategory {
    let id: String = "upcoming"
    let title: String = "Upcoming Assignments"
    var assignments: [AssignmentAPI]?
    var rules: AssignmentGroupRules? { nil }
    var groupWeight: Double? { nil }

    init(allAssignments: [AssignmentAPI]) {
        self.assignments = allAssignments
            .filter {
                ($0.dueDate ?? Date()) > Date()
            }
            .sorted { $0.dueDate ?? Date() < $1.dueDate ?? Date() }
    }
}

struct PastAssignmentsCategory: AssignmentGroupCategory {
    let id: String = "completed"
    let title: String = "Past Assignments"
    var assignments: [AssignmentAPI]?
    var rules: AssignmentGroupRules? { nil }
    var groupWeight: Double? { nil }

    init(allAssignments: [AssignmentAPI]) {
        self.assignments = allAssignments
            .filter {
                ($0.dueDate ?? Date()) < Date()
            }
            .sorted { $0.dueDate ?? Date() < $1.dueDate ?? Date() }
    }
}

extension AssignmentGroup: AssignmentGroupCategory {
    var title: String { self.name }
}
