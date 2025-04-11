//
//  MarkFavoriteRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 4/11/25.
//

import Foundation

struct APIFavorite: APIResponse {
    typealias Model = NoOpCacheable

    let context_id: String
    let context_type: ContextType

    enum ContextType: String, Codable {
        case course = "Course", group = "Group"

        var pathComponent: String {
            switch self {
            case .course:
                return "courses"
            case .group:
                return "groups"
            }
        }
    }
}

struct MarkFavoriteRequest: APIRequest {
    typealias Subject = APIFavorite

    var path: String { "/api/v1/users/self/favorites/\(contextType.pathComponent)/\(contextId)" }

    var method: RequestMethod { markFavorite ? .POST : .DELETE }

    let contextType: APIFavorite.ContextType
    let contextId: String
    let markFavorite: Bool

    var queryParameters: [QueryParameter] { [] }
}
