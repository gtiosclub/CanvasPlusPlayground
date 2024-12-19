//
//  AssignmentGroup.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/18/24.
//

import Foundation

struct AssignmentGroup: Codable, Identifiable {
    let id: Int?
    let name: String?
    let position: Int?
    let groupWeight: Int?
    let sisSourceID: String?
    let integrationData: [String: String]?
    let assignments: [Assignment]?
    let rules: GradingRules?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case position
        case groupWeight = "group_weight"
        case sisSourceID = "sis_source_id"
        case integrationData = "integration_data"
        case assignments
        case rules
    }
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
