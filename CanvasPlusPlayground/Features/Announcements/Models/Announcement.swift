//
//  Announcement.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/12/24.
//

import SwiftData
import Foundation

@Model
final class Announcement: Cacheable {
    typealias ID = String
    typealias ServerID = Int
    
    @Attribute(.unique) let id: String
    var courseID: String?

    var title: String?
    var createdAt: Date?
    var message: String?

    // MARK: Custom Properties
    var isRead: Bool?
    var summary: String?

    init(api: AnnouncementAPI) {
        self.id = api.id.asString
        self.title = api.title
        self.createdAt = api.created_at
        self.message = api.message
    }
    
    func merge(with other: Announcement) {
        self.title = other.title
        self.message = other.message
        self.createdAt = other.createdAt
    }
}
