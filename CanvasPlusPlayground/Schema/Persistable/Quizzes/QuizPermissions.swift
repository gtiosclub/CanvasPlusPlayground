//
//  QuizPermissions.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/14/24.
//

import Foundation

struct QuizPermissions: Codable {
    let read: Bool?
    let submit: Bool?
    let create: Bool?
    let manage: Bool?
    let readStatistics: Bool?
    let reviewGrades: Bool?
    let update: Bool?
    
    enum CodingKeys: String, CodingKey {
        case read
        case submit
        case create
        case manage
        case readStatistics = "read_statistics"
        case reviewGrades = "review_grades"
        case update
    }
}
