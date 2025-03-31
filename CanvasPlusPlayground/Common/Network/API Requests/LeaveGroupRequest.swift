//
//  LeaveGroupRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 3/29/25.
//

import Foundation

struct LeaveGroupRequest: NoReturnAPIRequest {
    var path: String { "groups/\(groupId)/\(via.pathComponent)" }
    var queryParameters: [QueryParameter] { [] }

    var method: RequestMethod { .DELETE }

    let groupId: String
    let via: Via
}

extension LeaveGroupRequest {
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
