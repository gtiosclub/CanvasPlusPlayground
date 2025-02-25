//
//  AssignmentGroupAPI.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 2/21/25.
//

import Foundation

// swiftlint:disable identifier_name
struct AssignmentGroupAPI: APIResponse {
    typealias Model = AssignmentGroup
    let id: Int
    let name: String
    let position: Int
    let group_weight: Double?
    let assignments: [AssignmentAPI]?
    let rules: AssignmentGroupRules?

    func createModel() -> AssignmentGroup {
        AssignmentGroup(from: self)
    }
}
// swiftlint:enable identifier_name

struct AssignmentGroupRules: Codable, Hashable {
    let dropHighest: Int?
    let dropLowest: Int?
    let neverDrop: [Int]?

    enum CodingKeys: String, CodingKey {
        case dropHighest = "drop_highest"
        case dropLowest = "drop_lowest"
        case neverDrop = "never_drop"
    }
}
