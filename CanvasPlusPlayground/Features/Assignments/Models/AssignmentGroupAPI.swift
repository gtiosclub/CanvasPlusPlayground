//
//  AssignmentGroupAPI.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 2/21/25.
//

import Foundation

struct AssignmentGroupAPI: APIResponse {
    typealias Model = AssignmentGroup

    // swiftlint:disable identifier_name
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

struct AssignmentGroupRules: Codable {
    let drop_highest: Int?
    let drop_lowest: Int?
    let never_drop: [Int]?
    // swiftlint:enable identifier_name
}
