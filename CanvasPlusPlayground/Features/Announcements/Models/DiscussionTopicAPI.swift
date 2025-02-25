//
//  DiscussionTopicAPI.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 2/15/25.
//

import Foundation

// swiftlint:disable commented_code identifier_name
// https://canvas.instructure.com/doc/api/discussion_topics.html#method.discussion_topics.index
struct DiscussionTopicAPI: APIResponse, Identifiable {
    typealias Model = DiscussionTopic

    // MARK: In Docs
    let id: Int
    let author: DiscussionParticipantAPI?
    let title: String?
    let message: String?
    let html_url: URL?
    let posted_at: Date?
    let last_reply_at: Date?
    let require_initial_post: Bool?
    let user_can_see_posts: Bool?
    let discussion_subentry_count: Int
    let read_state: DiscussionTopic.ReadState?
    let unread_count: Int?
    let subscribed: Bool?
    let subscription_hold: DiscussionTopic.SubscriptionHold?
    let assignment_id: Int?
    let delayed_post_at: Date?
    let published: Bool
    let lock_at: Date?
    let locked: Bool?
    let pinned: Bool?
    let locked_for_user: Bool
    // let lock_info: LockInfo?
    // let lock_explanation: String?
    let user_name: String?
    let group_topic_children: [DiscussionTopicChildAPI]?
    let root_topic_id: Int?
    let podcast_url: URL?
    let discussion_type: DiscussionTopic.DiscussionType?
    let group_category_id: Int?
    let attachments: [FileAPI]?
    let permissions: DiscussionPermissionsAPI?
    let allow_rating: Bool
    let only_graders_can_rate: Bool?
    let sort_by_rating: Bool

    // MARK: Not in Docs
    let context_code: String? // Only populated while using https://canvas.instructure.com/doc/api/announcements.html#method.announcements_api.index
    let is_announcement: Bool?
    let is_section_specific: Bool
    let anonymous_state: String?
    let assignment: [AssignmentAPI]?
    let position: Int?
    let created_at: Date?

    // MARK: Includes
    let sections: [APICourseSection]?

    func createModel() -> DiscussionTopic {
        DiscussionTopic(from: self)
    }
}

struct DiscussionTopicChildAPI: Codable {
    let id: Int
    let group_id: Int
}

struct DiscussionPermissionsAPI: Codable {
    let attach: Bool?
    let update: Bool?
    let reply: Bool?
    let delete: Bool?
}

struct DiscussionParticipantAPI: Codable {
    let id: Int?
    let display_name: String?
    let avatar_image_url: URL?
    let html_url: URL?
    let pronouns: String?
}
