//
//  GetUserRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/21/24.
//

import Foundation

/// Pass in `nil` as `userID` to fetch the current user.
struct GetUserRequest: APIRequest {
    typealias Subject = UserAPI
    
    let userId: String?
    var queryParameters: [QueryParameter] {
        []
    }
    
    var path: String { "users/\(userId ?? "self")" }
}
