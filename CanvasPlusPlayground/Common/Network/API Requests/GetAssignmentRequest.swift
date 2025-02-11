//
//  GetAssignmentRequest.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/8/25.
//

import Foundation

struct GetAssignmentRequest: APIRequest {
    typealias Subject = AssignmentAPI

    let assignmentId: String
    let courseId: String

    var path: String { "courses/\(courseId)/assignments/\(assignmentId)" }
    var queryParameters: [QueryParameter] {
        [
            ("override_assignment_dates", overrideAssignmentDates),
            ("needs_grading_count_by_section", needsGradingCountBySection),
            ("all_dates", allDates)
        ]
        + include.map { ("include[]", $0) }
    }

    // MARK: Query Params
    let include: [Include]
    let overrideAssignmentDates: Bool?
    let needsGradingCountBySection: Bool?
    let allDates: Bool?

    init(
        assignmentId: String,
        courseId: String,
        include: [Include] = [],
        overrideAssignmentDates: Bool? = nil,
        needsGradingCountBySection: Bool? = nil,
        allDates: Bool? = nil
    ) {
        self.assignmentId = assignmentId
        self.courseId = courseId
        self.include = include
        self.overrideAssignmentDates = overrideAssignmentDates
        self.needsGradingCountBySection = needsGradingCountBySection
        self.allDates = allDates
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
m
        return #Predicate<Assignment> { assignment in
            searchPred.evaluate(assignment) && assignmentIdsPred.evaluate(assignment) && postToSisPred.evaluate(assignment)
        }

        // TODO: add remaining filters (bucket, assignmentIds)
    }*/

}

extension GetAssignmentRequest {
    enum Include: String {
        case submission,
             assignmentVisibility = "assignment_visibility",
             overrides,
             observedUsers = "observed_users",
             canEdit = "can_edit",
             scoreStatistics = "score_statistics",
             abGuid = "ab_guid"
            
    }
}
