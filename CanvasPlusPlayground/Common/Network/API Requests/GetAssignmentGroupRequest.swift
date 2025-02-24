//
//  GetAssignmentGroupRequest.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 2/21/25.
//

import Foundation

struct GetAssignmentGroupsRequest: CacheableArrayAPIRequest {
    typealias Subject = AssignmentGroupAPI

    let courseId: String

    var path: String { "courses/\(courseId)/assignment_groups" }
    var queryParameters: [QueryParameter] {
        [
            ("include_all_dates", includeAllDates),
            ("override_assignment_dates", overrideAssignmentDates),
            ("grading_period_id", gradingPeriodId),
            ("scope_assignments_to_student", scopeAssignmentsToStudent)
        ]
        + include.map { ("include[]", $0.rawValue) }
        + excludeSubmissionTypes.map { ("exclude_assignment_submission_types[]", $0.rawValue) }
        + assignmentIds.map { ("assignment_ids[]", $0) }
    }

    // MARK: Query Params
    let include: [Include]
    let assignmentIds: [String]
    let excludeSubmissionTypes: [ExcludeSubmissionType]
    let includeAllDates: Bool?
    let overrideAssignmentDates: Bool?
    let gradingPeriodId: String?
    let scopeAssignmentsToStudent: Bool?

    init(
        courseId: String,
        include: [Include] = [],
        assignmentIds: [String] = [],
        excludeSubmissionTypes: [ExcludeSubmissionType] = [],
        includeAllDates: Bool? = nil,
        overrideAssignmentDates: Bool? = nil,
        gradingPeriodId: String? = nil,
        scopeAssignmentsToStudent: Bool? = nil
    ) {
        self.courseId = courseId
        self.include = include
        self.assignmentIds = assignmentIds
        self.excludeSubmissionTypes = excludeSubmissionTypes
        self.includeAllDates = includeAllDates
        self.overrideAssignmentDates = overrideAssignmentDates
        self.gradingPeriodId = gradingPeriodId
        self.scopeAssignmentsToStudent = scopeAssignmentsToStudent
    }

    var requestId: String { courseId }
    var requestIdKey: ParentKeyPath<AssignmentGroup, String> {
        .createWritable(\.tag)
    }
    var idPredicate: Predicate<AssignmentGroup> {
        #Predicate<AssignmentGroup> { group in
            group.tag == requestId
        }
    }
    var customPredicate: Predicate<AssignmentGroup> {
        let assignmentIdsPred = assignmentIds.isEmpty ? .true : #Predicate<AssignmentGroup> { group in
            group.assignments?
                .contains { assignmentIds.contains($0.id.asString) } ?? false
        }

        // TODO: Add excludeSubmissionTypes support

        return assignmentIdsPred
    }
}

// MARK: - Include Options
extension GetAssignmentGroupsRequest {
    enum Include: String {
        case assignments
        case discussionTopic = "discussion_topic"
        case allDates = "all_dates"
        case assignmentVisibility = "assignment_visibility"
        case overrides
        case submission
        case scoreStatistics = "score_statistics"
        case observedUsers = "observed_users"
        case canEdit = "can_edit"
    }

    enum ExcludeSubmissionType: String {
        case onlineQuiz = "online_quiz"
        case discussionTopic = "discussion_topic"
        case wikiPage = "wiki_page"
        case externalTool = "external_tool"
    }
}
