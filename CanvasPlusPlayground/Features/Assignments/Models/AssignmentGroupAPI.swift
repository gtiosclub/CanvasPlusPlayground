//
//  AssignmentGroupAPI.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/5/25.
//

import Foundation

struct AssignmentGroupAPI: APIResponse {
    typealias Model = NoOpCacheable

    // swiftlint:disable identifier_name
    let id: Int?
    let name: String?
    let position: Int?
    let group_weight: Int?
    let sis_source_id: String?
    let integration_data: [String: String]?
    let assignments: [AssignmentAPI]?
    let rules: GradingRules?
    // swiftlint:enable identifier_name
}

struct GradingRules: Codable {
    let dropLowest: Int?
    let dropHighest: Int?
    let neverDrop: [Int]?

    enum CodingKeys: String, CodingKey {
        case dropLowest = "drop_lowest"
        case dropHighest = "drop_highest"
        case neverDrop = "never_drop"
    }
}
