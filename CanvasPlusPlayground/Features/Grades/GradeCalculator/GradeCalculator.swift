//
//  GradeCalculatorViewModel.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 2/23/25.
//

import SwiftUI

@Observable
class GradeCalculator {
    struct GradeAssignment: Identifiable, Hashable {
        let id: String
        let name: String
        var pointsEarned: Double?
        var pointsPossible: Double?

        var percentage: Double? {
            guard let pointsEarned, let pointsPossible, pointsPossible > 0 else {
                return nil
            }
            return (pointsEarned / pointsPossible) * 100
        }
    }

    struct GradeGroup: Identifiable, Hashable {
        let id: String
        let name: String
        var weight: Double
        var assignments: [GradeAssignment]

        var rules: AssignmentGroupRules?

        var consideredAssignments: [GradeAssignment] {
            var retValue = assignments

            let neverDropAssignments = retValue.filter {
                guard let idAsInt = $0.id.asInt, let neverDrop = rules?.neverDrop else {
                    return false
                }

                return neverDrop.contains(idAsInt)
            }

            retValue = retValue.filter {
                guard let idAsInt = $0.id.asInt, let neverDrop = rules?.neverDrop else {
                    return true
                }

                return !neverDrop.contains(idAsInt)
            }

            if let dropLowest = rules?.dropLowest, dropLowest > 0 {
                retValue = Array(
                    retValue
                        .dropFirst(min(dropLowest, retValue.count))
                )
            }

            retValue.sort { ($0.pointsEarned ?? 0.0) > ($1.pointsEarned ?? 0.0) }

            if let dropHighest = rules?.dropHighest, dropHighest > 0 {
                retValue = Array(retValue.dropFirst(min(dropHighest, retValue.count)))
            }

            retValue += neverDropAssignments

            return retValue
        }

        var weightedScore: Double? {
            guard weight > 0.0, !assignments.isEmpty, assignments
                .contains( where: { $0.pointsEarned != nil }) else {
                return nil
            }

            let totalPossible = consideredAssignments.reduce(0.0) {
                guard $1.pointsEarned != nil else { return $0 }

                guard let pointsPossible = $1.pointsPossible else { return $0 }

                return $0 + pointsPossible
            }

            let totalEarned: Double = consideredAssignments.reduce(0.0) {
                guard let pointsEarned = $1.pointsEarned else { return $0 }

                return $0 + pointsEarned
            }

            guard totalPossible > 0 else { return nil }

            return (totalEarned / totalPossible) * weight
        }
    }

    var gradeGroups: [GradeGroup] = [] {
        didSet {
            calculateTotalGrade()
        }
    }
    var totalGrade: Double = 0.0
    var expandedAssignmentGroups: [GradeGroup: Bool] = [:]

    private func calculateTotalGrade() {
        let totalWeight = gradeGroups.reduce(0.0) {
            $0 + $1.weight
        }

        if totalWeight > 0 {
            var usedWeightage = 0.0

            let weightedTotal = gradeGroups.reduce(0.0) {sum, group in
                guard let weightedScore = group.weightedScore else { return sum }

                usedWeightage += group.weight

                LoggerService.main.debug(
                    "Group: \(group.name), Weight: \(group.weight), Score: \(weightedScore)"
                )

                return sum + weightedScore
            }

            LoggerService.main.debug(
                "Weighted Total: \(weightedTotal), Used Weightage: \(usedWeightage)"
            )

            totalGrade = (weightedTotal / usedWeightage) * 100
        } else {
            var totalPoints = 0.0
            var totalPossible = 0.0

            for group in gradeGroups {
                for assignment in group.assignments {
                    if let earned = assignment.pointsEarned,
                       let possible = assignment.pointsPossible {
                        totalPoints += earned
                        totalPossible += possible
                    }
                }
            }

            totalGrade = totalPossible > 0 ? (totalPoints / totalPossible) * 100 : 0.0
        }
    }

    init(assignmentGroups: [AssignmentGroup]) {
        resetGroups(assignmentGroups)
    }

    func resetGroups(_ assignmentGroups: [AssignmentGroup]) {
        self.gradeGroups = assignmentGroups.map { group in
            let assignments = group.assignments?.map { $0.createModel() }.map { assignment in
                GradeAssignment(
                    id: assignment.id,
                    name: assignment.name,
                    pointsEarned: assignment.submission?.score,
                    pointsPossible: assignment.pointsPossible ?? 0.0
                )
            } ?? []

            return GradeGroup(
                id: group.id,
                name: group.name,
                weight: group.groupWeight ?? 0.0,
                assignments: assignments,
                rules: group.rules
            )
        }

        expandedAssignmentGroups = Dictionary(
            uniqueKeysWithValues: gradeGroups.lazy.map { ($0, true) }
        )
    }
}
