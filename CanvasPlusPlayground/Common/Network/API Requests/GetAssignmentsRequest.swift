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
    let assignmentIds: [String?]
    let orderBy: String?
    let postToSis: Bool?
    let newQuizzes: Bool?
    let perPage: Int
    
    // MARK: Request Id
    var requestId: Int? { courseId.asInt }
    var requestIdKey: ParentKeyPath<Assignment, Int?> { .createReadable(\.courseId) }
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
    }
    
}
