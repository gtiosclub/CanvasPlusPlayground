//
//  GetAssignmentsRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/20/24.
//

import Foundation

struct GetAssignmentsRequest: ArrayAPIRequest {
    typealias Subject = AssignmentAPI

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
    let assignmentIds: [String?]
    let orderBy: String?
    let postToSis: Bool?
    let newQuizzes: Bool?
    let perPage: Int

    init(
        courseId: String,
        include: [String] = [],
        searchTerm: String? = nil,
        overrideAssignmentDates: Bool? = nil,
        needsGradingCountBySection: Bool? = nil,
        bucket: String? = nil,
        assignmentIds: [String?] = [],
        orderBy: String? = nil,
        postToSis: Bool? = nil,
        newQuizzes: Bool? = nil,
        perPage: Int = 50
    ) {
        self.courseId = courseId
        self.include = include
        self.searchTerm = searchTerm
        self.overrideAssignmentDates = overrideAssignmentDates
        self.needsGradingCountBySection = needsGradingCountBySection
        self.bucket = bucket
        self.assignmentIds = assignmentIds
        self.orderBy = orderBy
        self.postToSis = postToSis
        self.newQuizzes = newQuizzes
        self.perPage = perPage
    }

    /* Assignment isn't cacheable, reimplement when it is
    // MARK: Request Id
    var requestId: Int? { courseId.asInt }
    var requestIdKey: ParentKeyPath<Assignment, Int?> { .createReadable(\.courseId) }
    var idPredicate: Predicate<Assignment> {
        #Predicate<Assignment> { assignment in
            assignment.courseId == requestId
        }
    }
    var customPredicate: Predicate<Assignment> {
        let searchTerm = searchTerm ?? ""
        let searchPred = #Predicate<Assignment> { assignment in
            assignment.name.contains(searchTerm)
        }
        
        let ids = assignmentIds.compactMap(\.?.asInt)
        let assignmentIdsPred = assignmentIds.isEmpty ? .true :  #Predicate<Assignment> { assignment in
            ids.contains(assignment.id)
        }
        
        let postToSisPred: Predicate<Assignment>
        if let postToSis {
            postToSisPred = #Predicate<Assignment> { assignment in
                assignment.postToSis == postToSis
            }
        } else { postToSisPred = .true }
        
        return #Predicate<Assignment> { assignment in
            searchPred.evaluate(assignment) && assignmentIdsPred.evaluate(assignment) && postToSisPred.evaluate(assignment)
        }
         
        // TODO: add remaining filters (bucket, assignmentIds)
    }*/

}
