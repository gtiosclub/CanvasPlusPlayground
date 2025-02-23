//
//  AssignmentGroup.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 2/21/25.
//

import Foundation
import SwiftData

@Model
class AssignmentGroup: Cacheable {
    typealias ServerID = Int

    @Attribute(.unique) let id: String
    var name: String
    var position: Int
    var groupWeight: Double?
    var assignments: [AssignmentAPI]?

    // Rules
    var dropHighest: Int?
    var dropLowest: Int?
    var neverDrop: [Int]?

    // MARK: Custom Properties
    var tag: String

    init(from groupAPI: AssignmentGroupAPI) {
        self.id = groupAPI.id.asString
        self.name = groupAPI.name
        self.position = groupAPI.position
        self.groupWeight = groupAPI.group_weight
        self.assignments = groupAPI.assignments

        self.dropHighest = groupAPI.rules?.drop_highest
        self.dropLowest = groupAPI.rules?.drop_lowest
        self.neverDrop = groupAPI.rules?.never_drop

        self.tag = ""
    }

    func merge(with other: AssignmentGroup) {
        self.name = other.name
        self.position = other.position
        self.groupWeight = other.groupWeight
        self.dropHighest = other.dropHighest
        self.dropLowest = other.dropLowest
        self.neverDrop = other.neverDrop
        self.assignments = other.assignments
    }
}
