//
//  GetAssignmentRequest.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/8/25.
//

import Foundation

struct GetAssignmentRequest: CacheableAPIRequest {
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
        + include.map { ("include[]", $0.rawValue) }
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

    var requestId: String { assignmentId }
    var requestIdKey: ParentKeyPath<Assignment, String> { .createReadable(\.id) }
    var idPredicate: Predicate<Assignment> {
        #Predicate<Assignment> { assignment in
            assignment.id == requestId
        }
    }
    var customPredicate: Predicate<Assignment> {
        .true
    }
}

extension GetAssignmentRequest {
    enum Include: String {
        case submission,
             assignmentVisibility = "assignment_visibility",
             overrides,
             observedUsers = "observed_users",
             canEdit = "can_edit",
             scoreStatistics = "score_statistics",
             abGuid = "ab_guid",
             canSubmit = "can_submit"
    }
}
