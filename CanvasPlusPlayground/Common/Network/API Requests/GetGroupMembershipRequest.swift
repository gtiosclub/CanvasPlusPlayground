//
//  GetGroupMembershipRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 3/28/25.
//

import Foundation

struct GetGroupMembershipRequest: CacheableAPIRequest {
    typealias Subject = APIGroupMembership

    var path: String { "groups/\(groupId)/\(via.pathComponent)" }
    var queryParameters: [QueryParameter] { [] }

    let groupId: String
    let via: Via

    var requestId: String {
        via.id
    }
    var requestIdKey: ParentKeyPath<GroupMembership, String> {
        switch via {
        case .users:
            return .createReadable(\.userId.asString)
        case .memberships:
            return .createReadable(\.id)
        }
    }
    var idPredicate: Predicate<GroupMembership> {
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

extension GetGroupMembershipRequest {
    enum Via {
        case users(userId: String = "self"), memberships(membershipId: String)

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
