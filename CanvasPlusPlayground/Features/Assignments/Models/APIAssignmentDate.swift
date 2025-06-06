//
//  APIAssignmentDate.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/14/24.
//

import Foundation

// swiftlint:disable identifier_name
struct APIAssignmentDate: Codable, Hashable {
    var id: Int?
    var base: Bool?
    var title: String?
    var due_at: Date?
    var unlock_at: Date?
    var lock_at: Date?
}
