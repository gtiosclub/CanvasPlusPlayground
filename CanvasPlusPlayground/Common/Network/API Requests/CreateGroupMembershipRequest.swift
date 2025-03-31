//
//  CreateGroupMembershipRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 3/29/25.
//

import Foundation

struct CreateGroupMembershipRequest: CacheableAPIRequest {
    typealias Subject = APIGroupMembership

    var path: String { "groups/\(groupId)/memberships" }
    var queryParameters: [QueryParameter] { [] }

    var method: RequestMethod { .POST }

    let groupId: String
    let userId = "self"

    let boundary = UUID().uuidString
    var body: Data? {
        var body = Data()

        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".utf8))
        body.append(Data("\(userId)\r\n".utf8))
        body.append(Data("--\(boundary)--\r\n".utf8))

        return body
    }
    var contentType: String? { "multipart/form-data; boundary=\(boundary)" }

    var requestId: Int {
        groupId.asInt ?? -1
    }
    var requestIdKey: ParentKeyPath<GroupMembership, Int> {
        .createReadable(\.groupId)
    }
    var idPredicate: Predicate<GroupMembership> {
        let groupIdInt = requestId
        return #Predicate { $0.groupId == groupIdInt }
    }
    var customPredicate: Predicate<GroupMembership> { .true }
}
