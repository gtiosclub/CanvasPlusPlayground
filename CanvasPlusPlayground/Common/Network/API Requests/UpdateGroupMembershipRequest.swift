//
//  UpdateGroupMembershipRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 3/29/25.
//

import Foundation

struct UpdateGroupMembershipRequest: CacheableAPIRequest {
    typealias Subject = APIGroupMembership

    var path: String { "groups/\(groupId)/\(via.pathComponent)" }
    var queryParameters: [QueryParameter] {
        [
            ("workflow_state", toState.rawValue)
            // ("moderator", moderator_id)
        ]
    }

    var method: RequestMethod { .PUT }

    let groupId: String
    let toState: NewMembershipState
    // let moderator_id: String // For adding/removing moderator rights
    let via: Via

    var requestId: String {
        via.id != "self" ? via.id : "\(groupId)/self"
    }
    var requestIdKey: ParentKeyPath<GroupMembership, String> {
        guard via.id != "self" else {
            return .createWritable(\.tag)
        }

        switch via {
        case .users:
            return .createReadable(\.userId.asString)
        case .memberships:
            return .createReadable(\.id)
        }
    }
    var idPredicate: Predicate<GroupMembership> {
        guard via.id != "self" else {
            return #Predicate { requestId == $0.tag }
        }

        switch via {
        case .users:
            let requestIdInt = requestId.asInt ?? -1
            return #Predicate { requestIdInt == $0.userId }
        case .memberships:
            return #Predicate { requestId == $0.id }
        }
    }
    var customPredicate: Predicate<GroupMembership> { .true }
}

extension UpdateGroupMembershipRequest {
    enum NewMembershipState: String {
        case accepted
    }

    enum Via {
        case users(userId: String = "self"), memberships(membershipId: String = "self")

        var pathComponent: String {
            switch self {
            case .users(userId: let userId):
                return "users/\(userId)"
            case .memberships(membershipId: let membershipId):
                return "memberships/\(membershipId)"
            }
        }

        var id: String {
            switch self {
            case .users(let userId):
                return userId
            case .memberships(let membershipId):
                return membershipId
            }
        }
    }
}
