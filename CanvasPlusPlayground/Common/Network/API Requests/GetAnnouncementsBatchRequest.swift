//
//  GetAnnouncementsBatchRequest.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/19/25.
//

import Foundation

struct GetAnnouncementsBatchRequest: CacheableArrayAPIRequest {
    typealias Subject = AnnouncementAPI

    var path: String { "announcements" }

    var queryParameters: [QueryParameter] {
        [
            ("start_date", startDate?.ISO8601Format()),
            ("end_date", endDate?.ISO8601Format()),
            // ("active_only", activeOnly),  ONLY FOR TEACHERS
            ("latest_only", latestOnly),
            ("per_page", perPage)
        ]
        + contextCodes.map { ("context_codes[]", $0) }
        + include.map { ("include[]", $0.rawValue) }
    }

    // MARK: Query Params
    /// At least one context code must be provided here otherwise request fails
    let contextCodes: [String]
    let startDate: Date?
    let endDate: Date?
    // swiftlint:disable:next commented_code
    // let activeOnly: Bool? ONLY FOR TEACHERS
    let latestOnly: Bool?
    let include: [Include]
    let perPage: Int

    init(
        courseIds: [String],
        startDate: Date? = nil,
        endDate: Date? = nil,
        latestOnly: Bool? = nil,
        include: [Include] = [],
        perPage: Int = 50
    ) {
        assert(!courseIds.isEmpty)

        self.contextCodes = courseIds.map { "course_\($0)" }
        self.startDate = startDate
        self.endDate = endDate
        self.latestOnly = latestOnly
        self.include = include
        self.perPage = perPage
    }

    var requestId: String? { "announcements/\(contextCodes.joined(separator: "_"))" }
    var requestIdKey: ParentKeyPath<Announcement, String?> {
        .createReadable(\.contextCode)
    }
    var idPredicate: Predicate<Announcement> {
        let contextCodes = contextCodes as [String?]
        return contextCodes.isEmpty ? .true : #Predicate<Announcement> { announcement in
            contextCodes.contains(announcement.contextCode)
        }
    }
    var customPredicate: Predicate<Announcement> {
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
            startDatePredicate.evaluate(announcement) && endDatePredicate.evaluate(announcement)
        }
    }
}

extension GetAnnouncementsBatchRequest {
    enum Include: String {
        case sections,
             sectionsUserCount = "sections_user_count"
    }
}
