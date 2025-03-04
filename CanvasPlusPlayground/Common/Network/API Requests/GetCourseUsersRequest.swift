//
//  GetCourseUsersRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/20/25.
//

import Foundation

struct GetCourseUsersRequest: CacheableArrayAPIRequest {
    typealias Subject = UserAPI

    let courseId: String

    var path: String { "courses/\(courseId)/users" }
    var queryParameters: [QueryParameter] {
        [
            ("search_term", searchTerm),
            ("sort", sort),
            ("user_id", userId),
            ("per_page", perPage)
        ]
        + include.map { ("include[]", $0.rawValue) }
        + enrollmentType.map { ("enrollment_type[]", $0.asFilter) }
        + userIds.map { ("user_ids[]", $0) }
        + enrollmentState.map { ("enrollment_state", $0) }
    }

    let include: [Include]
    let searchTerm: String?
    let sort: Sorter?
    let enrollmentType: [EnrollmentType]
    let userId: String?
    let userIds: [String]
    let enrollmentState: [EnrollmentState]
    let perPage: Int

    var requestId: String? { courseId }
    var requestIdKey: ParentKeyPath<User, String?> {
        .createWritable(\.courseId)
    }
    var idPredicate: Predicate<User> {
        #Predicate {
            $0.courseId == requestId
        }
    }
    var customPredicate: Predicate<User> {
        let searchTerm = searchTerm ?? ""
        let searchPred = searchTerm.isEmpty ? .true : #Predicate<User> { user in
            user.name.localizedStandardContains(searchTerm)
        }

        // TODO: add enrollmentType pred - needs enrollment object
        let userId = self.userId ?? ""
        let userIdPred = self.userId == nil ? .true : #Predicate<User> { user in
            user.id == userId
        }
        let userIdsPred = self.userIds.isEmpty ? .true : #Predicate<User> { user in
            userIds.contains(user.id)
        }
        // TODO: add enrollmentState pred

        return #Predicate {
            searchPred.evaluate($0)
            && userIdPred.evaluate($0)
            && userIdsPred.evaluate($0)
        }
    }
}

extension GetCourseUsersRequest {
    enum Include: String {
        case enrollments = "enrollments",
             locked,
             avatarUrl = "avatar_url",
             bio,
             testStudent = "test_student",
             customLinks = "custom_links",
             currentGradingPeriodScores = "current_grading_period_scores",
             uuid,
             pronouns
    }

    enum Sorter: String {
        case username, lastLogin = "last_login", email, sisId = "sis_id"
    }

    enum EnrollmentState: String {
        case active, invited, rejected, completed, inactive
    }
}
