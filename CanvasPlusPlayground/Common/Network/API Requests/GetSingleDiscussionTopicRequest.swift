//
//  GetSingleDiscussionTopicRequest.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 4/10/25.
//

import Foundation

struct GetSingleDiscussionTopicRequest: CacheableArrayAPIRequest {
    typealias Subject = DiscussionTopicAPI

    let courseId: String
    let topicId: String

    var path: String { "courses/\(courseId)/discussion_topics/\(topicId)" }

    var queryParameters: [QueryParameter] {
        include.map { ("include[]", $0.rawValue) }
    }

    let include: [Include]

    var requestId: String { topicId }

    var requestIdKey: ParentKeyPath<DiscussionTopic, String> {
        .createReadable(\.id)
    }

    var idPredicate: Predicate<DiscussionTopic> {
        #Predicate {
            $0.id == topicId
        }
    }
    var customPredicate: Predicate<DiscussionTopic> {
        .true
    }
}

extension GetSingleDiscussionTopicRequest {
    enum Include: String {
        case allDates = "all_dates", sections, sectionsUserCount = "sections_user_count", overrides
    }
}
