//
//  GetDiscussionTopicsRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 2/15/25.
//

import Foundation

struct GetDiscussionTopicsRequest: CacheableArrayAPIRequest {
    typealias Subject = DiscussionTopicAPI

    let courseId: String

    var path: String { "courses/\(courseId)/discussion_topics" }

    var queryParameters: [QueryParameter] {
        [
            ("order", orderBy?.rawValue),
            ("scope", scope?.rawValue),
            ("only_announcements", onlyAnnouncements),
            ("filter_by", filterBy?.rawValue),
            ("search_term", searchTerm),
            ("exclude_content_module_locked_topics", excludeContentModuleLockedTopics),
            ("per_page", perPage)
        ]
        + include.map { ("include[]", $0.rawValue) }
    }

    let include: [Include]
    let orderBy: Order?
    let scope: Scope?
    let onlyAnnouncements: Bool
    let filterBy: Filter?
    let searchTerm: String?
    let excludeContentModuleLockedTopics: Bool
    let perPage: Int

    var requestId: String? { courseId }
    var requestIdKey: ParentKeyPath<DiscussionTopic, String?> { .createWritable(\.courseId) }
    var idPredicate: Predicate<DiscussionTopic> {
        #Predicate {
            $0.courseId == courseId
        }
    }
    var customPredicate: Predicate<DiscussionTopic> {
//        let scope = self.scope
//        let scopePred = switch scope {
//            case .locked:
//                #Predicate<DiscussionTopic> { topic in
//                    topic.locked
//                }
//
//            case .unlocked:
//                #Predicate<DiscussionTopic> { topic in
//                    !topic.locked
//                }
//
//            case .pinned:
//                #Predicate<DiscussionTopic> { topic in
//                    topic.pinned
//                }
//
//            case .unpinned:
//                #Predicate<DiscussionTopic> { topic in
//                    !topic.pinned
//                }
//
//            default:
//                .true
//        }
        // TODO: implement scope filter

//        let filterBy = self.filterBy
//        let filterPred = filterBy != nil ? #Predicate<DiscussionTopic> { topic in
//            (topic.readState == .unread && filterBy == .unread) || filterBy == .all
//        } : .true
        // TODO: implement filterBy

        let announcementPred = onlyAnnouncements ? #Predicate<DiscussionTopic> { topic in
            topic.isAnnouncement
        } : .true

        let searchTerm = searchTerm ?? ""
        let searchPred = searchTerm.isEmpty ? .true : #Predicate<DiscussionTopic> { topic in
            topic.title?.localizedStandardContains(searchTerm) ?? false
        }

        // TODO: filter for `excludeContentModuleLockedTopics` needed

        return #Predicate {
//            scopePred.evaluate($0)
//            filterPred.evaluate($0)
            announcementPred.evaluate($0)
            && searchPred.evaluate($0)
        }
    }

}

extension GetDiscussionTopicsRequest {
    enum Include: String {
        case allDates = "all_dates", sections, sectionsUserCount = "sections_user_count", overrides
    }

    enum Order: String {
        case position, recentActivity = "recent_activity", title
    }

    enum Scope: String {
        case locked, unlocked, pinned, unpinned
    }

    enum Filter: String {
        case all, unread
    }
}
