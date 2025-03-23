//
//  Group.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 3/23/25.
//

import Foundation
import SwiftData

@Model
class CanvasGroup: Cacheable {
    var id: String
    var name: String
    var groupDescription: String?
    var concluded: Bool
    var membersCount: Int
    var courseId: Int?
    var groupCategoryId: Int?
    var groupCategoryName: String?
    var groupLimit: Int
    var allowsMultipleMemberships: Bool?
    var storageQuotaMb: Int?
    var isPublic: Bool
    var users: [User]?
    var joinLevel: GroupJoinLevel?
    var avatarUrl: URL?

    // MARK: Permissions
    var canCreateDiscussionTopic: Bool?
    var canJoin: Bool?
    var canCreateAnnouncement: Bool?

    // MARK: Custom
    var usersIsIncomplete: Bool {
        membersCount > users?.count ?? 0
    }

    init(from api: APIGroup) {
        self.id = api.id.asString
        self.name = api.name
        self.groupDescription = api.description
        self.concluded = api.concluded
        self.membersCount = api.members_count
        self.courseId = api.course_id
        self.groupCategoryId = api.group_category?.id
        self.groupCategoryName = api.group_category?.name
        self.groupLimit = api.group_category?.group_limit ?? api.max_membership ?? .max
        self.allowsMultipleMemberships = api.group_category?.allows_multiple_memberships
        self.storageQuotaMb = api.storage_quota_mb
        self.isPublic = api.is_public

        self.users = api.users?.map {
            let user = User(from: $0)
            ModelContext.shared.insert(user)

            return user
        }

        self.joinLevel = api.join_level
        self.avatarUrl = api.avatar_url

        self.canCreateDiscussionTopic = api.permissions?.create_discussion_topic
        self.canJoin = api.permissions?.join
        self.canCreateAnnouncement = api.permissions?.create_announcement
    }

    func merge(with other: CanvasGroup) {
        self.name = other.name
        self.concluded = other.concluded
        self.groupDescription = other.groupDescription ?? self.groupDescription
        self.membersCount = other.membersCount
        self.courseId = other.courseId ?? self.courseId
        self.groupCategoryId = other.groupCategoryId ?? self.groupCategoryId
        self.groupCategoryName = other.groupCategoryName ?? self.groupCategoryName
        self.groupLimit = other.groupLimit
        self.allowsMultipleMemberships = other.allowsMultipleMemberships ?? self.allowsMultipleMemberships
        self.storageQuotaMb = other.storageQuotaMb ?? self.storageQuotaMb
        self.isPublic = other.isPublic

        self.users = other.users ?? self.users
        self.joinLevel = other.joinLevel ?? self.joinLevel
        self.avatarUrl = other.avatarUrl ?? self.avatarUrl

        self.canCreateDiscussionTopic = other.canCreateDiscussionTopic ?? self.canCreateDiscussionTopic
        self.canJoin = other.canJoin ?? self.canJoin
        self.canCreateAnnouncement = other.canCreateAnnouncement ?? self.canCreateAnnouncement
    }
}
