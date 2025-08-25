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
    class AssignmentGroup {
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

            if let rules = groupAPI.rules {
                self.rules = .init(from: rules)
            }

            self.tag = ""
        }
    }
}

struct AssignmentGroupRules: Codable, Hashable {
    let dropHighest: Int?
    let dropLowest: Int?
    let neverDrop: [Int]?

    init(from apiRules: AssignmentGroupRulesAPI) {
        self.dropHighest = apiRules.drop_highest
        self.dropLowest = apiRules.drop_lowest
        self.neverDrop = apiRules.never_drop
    }
}

extension AssignmentGroup: Cacheable {
    func merge(with other: AssignmentGroup) {
        self.name = other.name
        self.position = other.position
        self.groupWeight = other.groupWeight
        self.rules = other.rules
        self.assignments = other.assignments
    }
}
