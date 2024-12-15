//
//  AssignmentDate.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/14/24.
//

import Foundation

struct AssignmentDate: Codable, Hashable {
    var id: Int?
    var base: Bool?
    var title: String?
    var dueAt: Date?
    var unlockAt: Date?
    var lockAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case base
        case title
        case dueAt = "due_at"
        case unlockAt = "unlock_at"
        case lockAt = "lock_at"
    }
}
