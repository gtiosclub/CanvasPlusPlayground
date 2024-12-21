//
//  GetAnnouncementsRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/20/24.
//

import Foundation

struct GetAnnouncementsRequest: ArrayAPIRequest, CacheableAPIRequest {
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
    
    init(courseId: String, contextCodes: [String] = [], startDate: Date? = nil, endDate: Date? = nil, latestOnly: Bool? = nil, include: [String] = [], perPage: Int = 50) {
        self.courseId = courseId
        self.contextCodes = contextCodes
        self.startDate = startDate
        self.endDate = endDate
        self.latestOnly = latestOnly
        self.include = include
        self.perPage = perPage
    }
    
    var requestId: String { courseId }
    var requestIdKey: ParentKeyPath<Announcement, String> { .createWritable(\.parentId) }
    var idPredicate: Predicate<Announcement> {
        #Predicate<Announcement> { announcement in
            announcement.parentId == requestId
        }
    }
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