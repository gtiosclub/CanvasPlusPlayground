//
//  GroupMembership.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 3/23/25.
//

import Foundation
import SwiftData

typealias GroupMembership = CanvasSchemaV1.GroupMembership

extension CanvasSchemaV1 {
    @Model
    class GroupMembership: Hashable {
        var id: String
        var groupId: Int
        var userId: Int
        var workflowState: GroupMembershipState
        var isModerator: Bool?

        // MARK: Custom
        var tag: String = "" // for fetching from cache when `self` is passed as id

        init(from api: APIGroupMembership) {
            self.id = api.id.asString
            self.groupId = api.group_id
            self.userId = api.user_id
            self.workflowState = api.workflow_state
            self.isModerator = api.moderator
        }
    }
}

extension GroupMembership: Cacheable {
    func merge(with other: GroupMembership) {
        self.groupId = other.groupId
        self.userId = other.userId
        self.workflowState = other.workflowState
        self.isModerator = other.isModerator ?? self.isModerator
    }
}
