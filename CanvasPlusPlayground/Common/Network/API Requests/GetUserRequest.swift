//
//  GetUserRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/21/24.
//

import Foundation

struct GetUserRequest: CacheableAPIRequest {
    typealias Subject = UserAPI

    let userId: String
    var queryParameters: [QueryParameter] {
        []
    }

    /// Pass in `nil` as `userID` to fetch the current user.
    init(userId: String? = nil) {
        self.userId = userId ?? "self"
    }

    var path: String { "users/\(userId)" }

    var requestId: String { userId }
    var requestIdKey: ParentKeyPath<User, String> { .createWritable(\.tag) }
    var idPredicate: Predicate<User> {
        #Predicate<User> { user in
            user.tag == userId
        }
    }
    var customPredicate: Predicate<User> {
        .true
    }
}
