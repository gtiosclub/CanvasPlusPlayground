//
//  GetAssignmentGroupsRequest.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/5/25.
//

import Foundation

struct GetAssignmentGroupsRequest: ArrayAPIRequest {
    typealias Subject = AssignmentGroupAPI

    let courseId: String

    // Path for the request
    var path: String { "courses/\(courseId)/assignment_groups" }

    // Query parameters
    var queryParameters: [QueryParameter] {
        [
            ("override_assignment_dates", overrideAssignmentDates),
            ("grading_period_id", gradingPeriodId),
            ("scope_assignments_to_student", scopeAssignmentsToStudent)
        ]
        + include.map { ("include[]", $0) }
        + assignmentIds.map { ("assignment_ids[]", $0) }
        + excludeAssignmentSubmissionTypes.map { ("exclude_assignment_submission_types[]", $0) }
    }

    // MARK: Query Params
    let include: [String]
    let assignmentIds: [String]
    let excludeAssignmentSubmissionTypes: [String]
    let overrideAssignmentDates: Bool?
    let gradingPeriodId: Int?
    let scopeAssignmentsToStudent: Bool?

    // Initializer
    init(
        courseId: String,
        include: [String] = [],
        assignmentIds: [String] = [],
        excludeAssignmentSubmissionTypes: [String] = [],
        overrideAssignmentDates: Bool? = nil,
        gradingPeriodId: Int? = nil,
        scopeAssignmentsToStudent: Bool? = nil
    ) {
        self.courseId = courseId
        self.include = include
        self.assignmentIds = assignmentIds
        self.excludeAssignmentSubmissionTypes = excludeAssignmentSubmissionTypes
        self.overrideAssignmentDates = overrideAssignmentDates
        self.gradingPeriodId = gradingPeriodId
        self.scopeAssignmentsToStudent = scopeAssignmentsToStudent
    }

    /* MARK: Request Caching (Optional Implementation)
    var requestId: Int? { courseId.asInt }
    var requestIdKey: ParentKeyPath<AssignmentGroup, Int?> { .createReadable(\.courseId) }
    var idPredicate: Predicate<AssignmentGroup> {
        #Predicate<AssignmentGroup> { group in
            group.courseId == requestId
        }
    }

    var customPredicate: Predicate<AssignmentGroup> {
        let ids = assignmentIds.compactMap(\.?.asInt)
        let assignmentIdsPred = assignmentIds.isEmpty ? .true :  #Predicate<AssignmentGroup> { group in
            ids.contains(group.id)
        }
        return assignmentIdsPred
    }
    */
}
