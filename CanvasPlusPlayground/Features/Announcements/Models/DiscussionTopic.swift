//
//  DiscussionTopic.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 2/15/25.
//

import SwiftData
import Foundation

@Model
class DiscussionTopic: Cacheable, Hashable, Equatable {

    var id: String

    // MARK: In Docs
    var author: DiscussionParticipantAPI?
    var title: String?
    var message: String?
    var htmlURL: URL?
    var postedAt: Date?
    var lastReplyAt: Date?
    var requireInitialPost: Bool
    var userCanSeePosts: Bool
    var discussionSubentryCount: Int
    var readState: ReadState?
    var unreadCount: Int?
    var subscribed: Bool
    var subscriptionHold: SubscriptionHold?
    var assignmentId: Int?
    var delayedPostAt: Date?
    var published: Bool
    var lockAt: Date?
    var locked: Bool
    var pinned: Bool
    var lockedForUser: Bool
    // let lock_info: LockInfo?
    // let lock_explanation: String?
    var userName: String?
    var groupTopicChildren: [DiscussionTopicChildAPI]?
    var rootTopicId: Int?
    var podcastUrl: URL?
    var discussionType: DiscussionType?
    var groupCategoryId: Int?
    var attachments: [FileAPI]?
    var permissions: DiscussionPermissionsAPI?
    var allowRating: Bool
    var onlyGradersCanRate: Bool
    var sortByRating: Bool

    // MARK: Not in Docs
    var contextCode: String? // Only populated while using https://canvas.instructure.com/doc/api/announcements.html#method.announcements_api.index
    var isAnnouncement: Bool
    var isSectionSpecific: Bool
    var anonymousState: String?
    var assignment: [AssignmentAPI]
    var position: Int?
    var createdAt: Date?

    // MARK: Includes
    var sections: [APICourseSection]

    // MARK: Custom
    var courseId: String?
    var summary: String?

    var isRead: Bool {
        get { readState == .read }
        set { readState = newValue == true ? .read : .unread }
    }

    var date: Date? {
        postedAt ?? createdAt ?? delayedPostAt
    }

    var readActionLabel: String {
        self.readState?.actionLabel ?? ReadState.read.actionLabel
    }

    init(from topicAPI: DiscussionTopicAPI) {
        self.id = topicAPI.id.asString
        self.author = topicAPI.author
        self.title = topicAPI.title
        self.message = topicAPI.message
        self.htmlURL = topicAPI.html_url
        self.postedAt = topicAPI.posted_at
        self.lastReplyAt = topicAPI.last_reply_at
        self.requireInitialPost = topicAPI.require_initial_post ?? false
        self.userCanSeePosts = topicAPI.user_can_see_posts ?? false
        self.discussionSubentryCount = topicAPI.discussion_subentry_count
        self.readState = topicAPI.read_state
        self.unreadCount = topicAPI.unread_count
        self.subscribed = topicAPI.subscribed ?? false
        self.subscriptionHold = topicAPI.subscription_hold
        self.assignmentId = topicAPI.assignment_id
        self.delayedPostAt = topicAPI.delayed_post_at
        self.published = topicAPI.published
        self.lockAt = topicAPI.lock_at
        self.locked = topicAPI.locked ?? false
        self.pinned = topicAPI.pinned ?? false
        self.lockedForUser = topicAPI.locked_for_user
        self.userName = topicAPI.user_name
        self.groupTopicChildren = topicAPI.group_topic_children
        self.rootTopicId = topicAPI.root_topic_id
        self.podcastUrl = topicAPI.podcast_url
        self.discussionType = topicAPI.discussion_type
        self.groupCategoryId = topicAPI.group_category_id
        self.attachments = topicAPI.attachments
        self.permissions = topicAPI.permissions
        self.allowRating = topicAPI.allow_rating
        self.onlyGradersCanRate = topicAPI.only_graders_can_rate ?? false
        self.sortByRating = topicAPI.sort_by_rating

        self.isAnnouncement = topicAPI.is_announcement ?? false
        self.isSectionSpecific = topicAPI.is_section_specific
        self.anonymousState = topicAPI.anonymous_state
        self.assignment = topicAPI.assignment ?? []
        self.position = topicAPI.position
        self.sections = topicAPI.sections ?? []
        self.createdAt = topicAPI.created_at
    }

    func merge(with other: DiscussionTopic) {
        author = other.author
        title = other.title ?? title
        message = other.message ?? message
        htmlURL = other.htmlURL ?? htmlURL
        postedAt = other.postedAt ?? postedAt
        lastReplyAt = other.lastReplyAt ?? lastReplyAt
        requireInitialPost = other.requireInitialPost
        userCanSeePosts = other.userCanSeePosts
        discussionSubentryCount = other.discussionSubentryCount
        readState = other.readState ?? readState
        unreadCount = other.unreadCount ?? unreadCount
        subscribed = other.subscribed
        subscriptionHold = other.subscriptionHold ?? subscriptionHold
        assignmentId = other.assignmentId ?? assignmentId
        delayedPostAt = other.delayedPostAt ?? delayedPostAt
        published = other.published
        lockAt = other.lockAt ?? lockAt
        locked = other.locked
        pinned = other.pinned
        lockedForUser = other.lockedForUser
        userName = other.userName ?? userName

        if let otherGroupTopicChildren = other.groupTopicChildren {
            groupTopicChildren = otherGroupTopicChildren
        }

        rootTopicId = other.rootTopicId ?? rootTopicId
        podcastUrl = other.podcastUrl ?? podcastUrl
        discussionType = other.discussionType ?? discussionType
        groupCategoryId = other.groupCategoryId ?? groupCategoryId

        if let otherAttachments = other.attachments {
            attachments = otherAttachments
        }

        if let otherPermissions = other.permissions {
            permissions = otherPermissions
        }

        // Rating-related properties
        allowRating = other.allowRating
        onlyGradersCanRate = other.onlyGradersCanRate
        sortByRating = other.sortByRating

        // Non-documented properties
        contextCode = other.contextCode ?? contextCode
        isAnnouncement = other.isAnnouncement
        isSectionSpecific = other.isSectionSpecific
        anonymousState = other.anonymousState ?? anonymousState
        assignment = other.assignment
        position = other.position ?? position

        // Includes
        if !other.sections.isEmpty {
            sections = other.sections
        }
    }

    enum ReadState: String, Codable {
        case read, unread

        var actionLabel: String {
            switch self {
            case .read:
                return "Mark as unread"
            case .unread:
                return "Mark as read"
            }
        }
    }

    enum SubscriptionHold: String, Codable {
        case initialPostRequired = "initial_post_required", notInGroupSet = "not_in_group_set", notInGroup = "not_in_group", topicIsAnnouncement = "topic_is_announcement"
    }

    enum DiscussionType: String, Codable {
        case sideComment = "side_comment", notThreaded = "not_threaded", threaded
    }
}

// MARK: Errors

extension DiscussionTopic {

    /// Errors related to discussion topic
    enum Error: Swift.Error {
        case courseIdMissing
    }
}

// MARK: Read Marking
extension DiscussionTopic {

    func markReadStatus(_ isRead: Bool) async throws {
        guard let courseId = self.courseId else {
            LoggerService.main.debug("[markAsRead] Course id missing")
            throw Error.courseIdMissing
        }

        self.isRead = true

        if isRead {
            let request = CanvasRequest.markCourseDiscussionTopicAsRead(courseId: courseId, discussionTopicId: self.id)
            try await CanvasService.shared.fetch(request)
        } else {
            let request = CanvasRequest.markCourseDiscussionTopicAsUnread(courseId: courseId, discussionTopicId: self.id)
            try await CanvasService.shared.fetch(request)
        }
    }

    func toggleReadState() async throws {
        if self.isRead {
            try await self.markReadStatus(true)
        } else {
            try await self.markReadStatus(false)
        }
    }
}
