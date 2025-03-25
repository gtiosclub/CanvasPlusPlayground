//
//  APIGroup.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 3/23/25.
//

import Foundation

// swiftlint:disable identifier_name

struct APIGroup: APIResponse {
    typealias Model = CanvasGroup

    let id: Int
    let name: String
    let description: String?
    let concluded: Bool
    let members_count: Int
    let course_id: Int?
    let group_category: GroupCategory?
    let storage_quota_mb: Int?
    let is_public: Bool
    let users: [UserAPI]?
    let permissions: Permissions?
    let join_level: GroupJoinLevel?
    let avatar_url: URL?
    let max_membership: Int?

    func createModel() -> CanvasGroup {
        CanvasGroup(from: self)
    }

    struct GroupCategory: Codable {
        let id: Int?
        let name: String?
        let group_limit: Int?
        let allows_multiple_memberships: Bool?
    }

    struct Permissions: Codable {
        let create_discussion_topic: Bool
        let join: Bool
        let create_announcement: Bool
    }

    static let sample1 = APIGroup(
        id: 12345,
        name: "iOS Development Team",
        description: "A group for students working on the final iOS project",
        concluded: false,
        members_count: 6,
        course_id: 9876,
        group_category: APIGroup.GroupCategory(
            id: 42,
            name: "Project Teams",
            group_limit: 8,
            allows_multiple_memberships: false
        ),
        storage_quota_mb: 1024,
        is_public: false,
        users: [
            .sample1,
            .sample2
        ],
        permissions: APIGroup.Permissions(
            create_discussion_topic: true,
            join: false,
            create_announcement: true
        ),
        join_level: .invitationOnly,
        avatar_url: URL(string: "https://canvas.example.edu/groups/12345/avatar.png"),
        max_membership: 8
    )
}

enum GroupJoinLevel: String, Codable {
    case invitationOnly = "invitation_only"
    case parentContextRequest = "parent_context_request"
    case parentContextAutoJoin = "parent_context_auto_join"
}
