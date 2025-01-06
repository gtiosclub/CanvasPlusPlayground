//
//  CourseGradeCalculator.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/5/25.
//


import Foundation

struct CourseGradeCalculator {
    struct GradeCalculatorAssignmentGroup: Identifiable, Hashable {
        let id: Int
        let name: String
        var assignments: [GradeCalculatorAssignment]
        var groupWeight: Double

        var assignmentWeight: Double {
            groupWeight / Double(assignments.count)
        }

        var displayWeight: String {
            "\((groupWeight * 100.0).truncatingTrailingZeros)%"
        }
    }

    struct GradeCalculatorAssignment: Identifiable, Hashable {
        let id: Int
        let name: String
        var weight: Double?
        var pointsPossible: Double?
        var score: Double?
    }

    var assignmentGroups: [GradeCalculatorAssignmentGroup]

    var finalGrade: String {
        var grade = calculateFinalGrade()
        if grade.isNaN {
            grade = 0
        }

        return Double(grade * 100.0).rounded(toPlaces: 2) + "%"
    }

    init(from canvasAssignmentGroup: [AssignmentGroupAPI]) {
        assignmentGroups = canvasAssignmentGroup.map { group in
            GradeCalculatorAssignmentGroup(
                    id: group.id ?? UUID().hashValue,
                    name: group.name ?? "",
                    assignments: group.assignments?.map { assignment in
                        GradeCalculatorAssignment(
                                id: assignment.id,
                                name: assignment.name,
                                weight: nil,
                                pointsPossible: assignment.points_possible ?? 0,
                                score: assignment.submission?.score
                            )
                    } ?? [],
                    groupWeight: (Double(group.group_weight ?? 0) / 100.0)
                )
        }
    }

    // MARK: - Private
    private func calculateFinalGrade() -> Double {
        var totalWeight = assignmentGroups.reduce(0.0) { total, group in
            total + group.groupWeight
        }

        // Groups are unweighted
        if totalWeight == 0 {
            var totalPossible: Double = 0
            let earned: Double = assignmentGroups.reduce(0) { total, group in
                total + group.assignments.reduce(0) { total, assignment in
                    guard let score = assignment.score, let pointsPossible = assignment.pointsPossible else {
                        return total
                    }

                    totalPossible += pointsPossible

                    return Double(total + score)
                }
            }

            return earned / totalPossible
        } else {
            return assignmentGroups.reduce(0) { total, group in
                total + group.assignments.reduce(0) { total, assignment in
                    guard let score = assignment.score, let pointsPossible = assignment.pointsPossible else {
                        return total
                    }

                    return total + (score / pointsPossible) * (assignment.weight ?? group.assignmentWeight)
                }
            } / totalWeight
        }
    }
}
