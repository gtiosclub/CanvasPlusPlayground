//
//  GetAnnouncementsRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/20/24.
//

import Foundation

struct GetAnnouncementsRequest: ArrayAPIRequest {
    typealias Subject = Announcement
    
    let courseId: String
    
    var path: String { "announcements" }
    
    var queryParameters: [QueryParameter] {
        [
            ("start_date", startDate?.ISO8601Format()),
            ("end_date", endDate?.ISO8601Format()),
            ("active_only", activeOnly),
            ("latest_only", latestOnly),
            ("per_page", perPage)
        ]
        + (contextCodes + [courseId]).map { ("context_codes[]", $0) }
        + include.map { ("include[]", $0) }
    }
    
    // MARK: Query Params
    /// At least one courseId must be provided here otherwise request fails
    let contextCodes: [String]
    let startDate: Date?
    let endDate: Date?
    let activeOnly: Bool?
    let latestOnly: Bool?
    let include: [String]
    let perPage: Int
    
    var requestId: String { courseId }
    var requestIdKey: ParentKeyPath<Announcement, String> { .createWritable(\.parentId) }
    var customPredicate: Predicate<Announcement> {
        // TODO: match query params
        #Predicate<Announcement> { announcement in
            true
        }
    }
}
