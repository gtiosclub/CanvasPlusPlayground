//
//  Group.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 3/23/25.
//

import Foundation
import SwiftData

@Model
class CanvasGroup: Cacheable, Hashable {
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
    var users: [UserAPI]?
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
    var availableAction: GroupAction? {
        guard canJoin == true && !concluded else { return nil } // no action can be taken

        // make sure group has space to join OR user is already in group OR user already has request in progress. otherwise lock action.
        guard membersCount < groupLimit || currUserStatus == .accepted || currUserStatus == .requested else { return nil }

        return switch currUserStatus {
        case .accepted:
            .leave
        case .invited:
            .accept
        case .requested:
            .cancelRequest
        case nil:
            .join
        }
        // TODO: verify action logic + handle `Switch to`
    }
    // TODO: store GroupMembership as relationship instead
    var currUserStatus: GroupMembershipState? // should update by fetching GroupMembership of `self`
    @Attribute(.ephemeral) var isLoadingMembership: Bool = false

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

        // TODO: use user api instead
        self.users = api.users

        self.joinLevel = api.join_level
        self.avatarUrl = api.avatar_url

        self.canCreateDiscussionTopic = api.permissions?.create_discussion_topic
        self.canJoin = api.permissions?.join
        self.canCreateAnnouncement = api.permissions?.create_announcement
    }
}

enum GroupAction: String {
    case join = "Join", leave = "Leave", accept = "Accept", cancelRequest = "Cancel request"

    var label: String {
        self.rawValue
    }
}

// MARK: Cacheable
extension CanvasGroup {
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

// MARK: Preview
extension CanvasGroup {
    static let sample = CanvasGroup(
        from: .sample1
    )
}
