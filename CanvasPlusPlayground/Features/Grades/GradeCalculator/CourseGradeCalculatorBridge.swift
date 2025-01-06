//
//  CourseGradeCalculatorBridge.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/5/25.
//

import SwiftUI

@Observable
class CourseGradeCalculatorBridge {
    typealias GradeCalculatorAssignmentGroup = CourseGradeCalculator.GradeCalculatorAssignmentGroup

    // swiftlint:disable:next identifier_name
    private(set) var _calculator: CourseGradeCalculator

    var assignmentGroups: [GradeCalculatorAssignmentGroup] {
        get {
            _calculator.assignmentGroups
        }

        set {
            _calculator.assignmentGroups = newValue
        }
    }

    var finalGrade: String {
        _calculator.finalGrade
    }

    var expandedAssignmentGroups: [GradeCalculatorAssignmentGroup: Bool] = [:]

    init(from assignmentGroups: [AssignmentGroupAPI]) {
        _calculator = CourseGradeCalculator(from: assignmentGroups)
        expandedAssignmentGroups = Dictionary(
            uniqueKeysWithValues: _calculator.assignmentGroups.lazy.map { ($0, true) }
        )
    }
}
