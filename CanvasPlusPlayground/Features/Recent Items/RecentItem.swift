//
//  RecentItem.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/11/25.
//

import Foundation

enum RecentItemType: String, Codable {
    case announcement
    case assignment
    case file
    case quiz

    var displayName: String {
        switch self {
        case .announcement: "Announcement"
        case .assignment: "Assignment"
        case .file: "File"
        case .quiz: "Quiz"
        }
    }
}

@Observable
class RecentItem: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let courseID: String
    let type: RecentItemType
    let viewedAt: Date
    var data: RecentItemData?

    enum CodingKeys: String, CodingKey {
        case id
        case courseID
        case type
        case viewedAt
    }

    init(id: String, courseID: String, type: RecentItemType, viewedAt: Date = Date()) {
        self.id = id
        self.courseID = courseID
        self.type = type
        self.viewedAt = viewedAt
        self.data = nil
    }

    var uniqueKey: String {
        "\(type.rawValue)-\(courseID)-\(id)"
    }

    static func == (lhs: RecentItem, rhs: RecentItem) -> Bool {
        lhs.id == rhs.id && lhs.courseID == rhs.courseID && lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(courseID)
        hasher.combine(type)
    }
}
