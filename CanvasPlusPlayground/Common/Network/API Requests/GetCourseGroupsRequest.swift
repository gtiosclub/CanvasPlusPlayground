//
//  GetCourseGroupsRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 3/23/25.
//

import Foundation

struct GetCourseGroupsRequest: CacheableArrayAPIRequest {
    typealias Subject = APIGroup

    var path: String { "courses/\(courseId)/groups" }
    var queryParameters: [QueryParameter] {
        [
            ("only_own_groups", onlyOwnGroups),
            ("per_page", perPage),
            ("collaboration_state", collaborationState)
        ]
        + include.map { ("include[]", $0.rawValue) }
    }

    let courseId: String
    let onlyOwnGroups: Bool
    let include: [Include]
    let collaborationState: CollaborationState

    let perPage: Int

    var requestId: Int? { courseId.asInt }
    var requestIdKey: ParentKeyPath<CanvasGroup, Int?> {
        .createWritable(\.courseId)
    }
    var idPredicate: Predicate<CanvasGroup> {
        #Predicate { $0.courseId == requestId }
    }
    var customPredicate: Predicate<CanvasGroup> {
        if onlyOwnGroups {
            let accepted = GroupMembershipState.accepted as GroupMembershipState?
            return #Predicate<CanvasGroup> { $0.currUserStatus == accepted }
        } else { return .true }
        // TODO: collab state filter
    }
}

extension GetCourseGroupsRequest {
    enum Include: String {
        case tabs, permissions, groupCategory = "group_category", users
    }

    enum CollaborationState: String {
        case all, collaborative, nonCollaborative = "non_collaborative"
    }
}
