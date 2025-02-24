//
//  Pages.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 2/21/25.
//

import Foundation
import SwiftData

// swiftlint:disable commented_code
@Model
final class Page: Cacheable {
    typealias ID = String
    typealias ServerID = Int

    // MARK: IDs
    @Attribute(.unique) let id: String
    var courseID: String?

    // MARK: Page Details
    var pageId: Int
    var url: String
    var title: String?
    var createdAt: Date?
    var updatedAt: Date?
//    var editingRoles: String?
//    var lastEditedBy: String?
    var body: String?
    var published: Bool
    var publishAt: Date?
    var frontPage: Bool
//    var lockedForUser: Bool
//    var lockInfo: String?
//    var lockExplanation: String?
//    var editor: String?
//    var blockEditorAttributes: [String: Any]?

    var displayTitle: String {
        title ?? "Untitled Page"
    }

    init(pageAPI: PageAPI) {
        self.id = String(pageAPI.page_id)
        self.pageId = pageAPI.page_id
        self.url = pageAPI.url
        self.title = pageAPI.title
        self.createdAt = pageAPI.created_at
        self.updatedAt = pageAPI.updated_at
        self.body = pageAPI.body
        self.published = pageAPI.published
        self.publishAt = pageAPI.publish_at
        self.frontPage = pageAPI.front_page
    }

    func merge(with other: Page) {
        self.url = other.url
        self.title = other.title
        self.updatedAt = other.updatedAt
        self.body = other.body
        self.published = other.published
        self.publishAt = other.publishAt
        self.frontPage = other.frontPage
    }
}
