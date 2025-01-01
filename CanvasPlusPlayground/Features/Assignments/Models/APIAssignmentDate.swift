//
//  APIAssignmentDate.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/14/24.
//

import Foundation

struct APIAssignmentDate: Codable, Hashable {
    // swiftlint:disable identifier_name
    var id: Int?
    var base: Bool?
    var title: String?
    var due_at: Date?
    var unlock_at: Date?
    var lock_at: Date?
    // swiftlint:enable identifier_name
}
