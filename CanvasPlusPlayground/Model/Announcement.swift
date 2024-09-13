//
//  Announcement.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/12/24.
//

import Foundation

struct Announcement: Codable {
    let id:Int?
    let title:String?
    let createdAt:Date?
    let message:String?
    
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case title
        case message
    }
}
