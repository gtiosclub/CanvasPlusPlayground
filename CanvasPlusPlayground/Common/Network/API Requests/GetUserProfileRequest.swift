//
//  GetUserProfileRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/21/24.
//

import Foundation

struct GetUserProfileRequest: CacheableAPIRequest {
    typealias Subject = ProfileAPI

    let userId: String
    var queryParameters: [QueryParameter] {
        []
    }

    /// Pass in `nil` as `userID` to fetch the current user profile.
    init(userId: String? = nil) {
        self.userId = userId ?? "self"
    }

    var path: String { "users/\(userId)/profile" }

    var requestId: String { userId }
    var requestIdKey: ParentKeyPath<Profile, String> { .createWritable(\.tag) }
    var idPredicate: Predicate<Profile> {
        #Predicate<Profile> { profile in
            profile.tag == userId
        }
    }
    var customPredicate: Predicate<Profile> {
        .true
    }
}
