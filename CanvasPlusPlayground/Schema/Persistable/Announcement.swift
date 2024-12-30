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
    var title:String?
    var createdAt:Date?
    var message:String?

    // MARK: Custom Properties
    var isRead: Bool?
    var summary: String?

    weak var course: Course?
    var parentId: String

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(ServerID.self, forKey: .id)
        self.id = String(describing: id)

        self.parentId = try container.decodeIfPresent(String.self, forKey: .parentId) ?? ""

        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)

    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)

        try container.encodeIfPresent(parentId, forKey: .parentId)

        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(message, forKey: .message)
    }

    enum CodingKeys: String, CodingKey {
        case id

        case parentId = "parent_id"

        case createdAt = "created_at"
        case title
        case message
    }

    func merge(with other: Announcement) {
        self.title = other.title
        self.message = other.message
        self.createdAt = other.createdAt
    }
}
