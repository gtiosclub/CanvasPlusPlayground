//
//  AssignmentGroup.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 2/21/25.
//

import Foundation
import SwiftData

typealias AssignmentGroup = CanvasSchemaV1.AssignmentGroup

extension CanvasSchemaV1 {
    @Model
    class AssignmentGroup: Cacheable {
        typealias ServerID = Int

        @Attribute(.unique) let id: String
        var name: String
        var position: Int
        var groupWeight: Double?
        var assignments: [AssignmentAPI]?

        // Rules
        var rules: AssignmentGroupRules?

        // MARK: Custom Properties
        var tag: String

        init(from groupAPI: AssignmentGroupAPI) {
            self.id = groupAPI.id.asString
            self.name = groupAPI.name
            self.position = groupAPI.position
            self.groupWeight = groupAPI.group_weight
            self.assignments = groupAPI.assignments

            self.rules = groupAPI.rules

            self.tag = ""
        }

        func merge(with other: AssignmentGroup) {
            self.name = other.name
            self.position = other.position
            self.groupWeight = other.groupWeight
            self.rules = other.rules
            self.assignments = other.assignments
        }
    }
}
