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
            //("active_only", activeOnly),  ONLY FOR TEACHERS
            ("latest_only", latestOnly),
            ("per_page", perPage)
        ]
        + (contextCodes + ["course_\(courseId)"]).map { ("context_codes[]", $0) }
        + include.map { ("include[]", $0) }
    }
    
    // MARK: Query Params
    /// At least one courseId must be provided here otherwise request fails
    let contextCodes: [String]
    let startDate: Date?
    let endDate: Date?
    //let activeOnly: Bool? ONLY FOR TEACHERS
    let latestOnly: Bool?
    let include: [String]
    let perPage: Int
    
    var requestId: String { courseId }
    var requestIdKey: ParentKeyPath<Announcement, String> { .createWritable(\.parentId) }
    var customPredicate: Predicate<Announcement> {
        let contextCodePred = contextCodes.isEmpty ? .true : #Predicate<Announcement> { announcement in
            contextCodes.contains(announcement.parentId)
        }
        
        let startDatePredicate: Predicate<Announcement>
        if let startDate {
            startDatePredicate = #Predicate<Announcement> { announcement in
                if let createdAt = announcement.createdAt {
                    startDate <= (createdAt)
                } else { true }
            }
        } else { startDatePredicate = .true }
        
        let endDatePredicate: Predicate<Announcement>
        if let endDate {
            endDatePredicate = #Predicate<Announcement> { announcement in
                if let createdAt = announcement.createdAt {
                    endDate >= createdAt
                } else { true }
            }
        } else { endDatePredicate = .true }
        
        return #Predicate<Announcement> { announcement in
            contextCodePred.evaluate(announcement) && startDatePredicate.evaluate(announcement) && endDatePredicate.evaluate(announcement)
        }
    }
}
