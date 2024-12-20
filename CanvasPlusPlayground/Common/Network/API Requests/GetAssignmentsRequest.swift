//
//  GetAssignmentsRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/20/24.
//

import Foundation

struct GetAssignmentsRequest: ArrayAPIRequest {
    typealias Subject = Assignment
    
    let courseId: String
    
    var path: String { "courses/\(courseId)/assignments" }
    var queryParameters: [QueryParameter] {
        [
            ("search_term", searchTerm),
            ("override_assignment_dates", overrideAssignmentDates),
            ("needs_grading_count_by_section", needsGradingCountBySection),
            ("bucket", bucket),
            ("order_by", orderBy),
            ("post_to_sis", postToSis),
            ("new_quizzes", newQuizzes),
            ("per_page", perPage)
        ]
        + include.map { ("include[]", $0) }
        + assignmentIds.map { ("assignment_ids[]", $0) }
    }
    
    // MARK: Query Params
    let include: [String]
    let searchTerm: String?
    let overrideAssignmentDates: Bool?
    let needsGradingCountBySection: Bool?
    let bucket: String?
    let assignmentIds: [String]
    let orderBy: String?
    let postToSis: Bool?
    let newQuizzes: Bool?
    let perPage: Int
    
    // MARK: Request Id
    var requestId: Int? { courseId.asInt }
    var requestIdKey: ParentKeyPath<Assignment, Int?> { .createReadable(\.courseId) }
    var customPredicate: Predicate<Assignment> {
        #Predicate<Assignment> { assignment in
            true
        }
    }
    
}
