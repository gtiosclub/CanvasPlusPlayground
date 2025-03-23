//
//  APIGroupMembership.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 3/23/25.
//

import Foundation

struct APIGroupMembership: APIResponse {
    let id: Int
    let group_id: Int
    let user_id: Int
    let workflow_state: GroupMembershipState
    let moderator: Bool?
    //let just_created: Bool?
}

enum GroupMembershipState: String, Codable {
    case accepted, invited, requested
}
