//
//  Assignment.swift
//  CanvasPlusPlayground
//
//  Created by Sankaet Cheemalamarri on 9/14/24.
//

import Foundation

/*
 {"id":20960000000853302,
 "description":"\u003clink rel=\"stylesheet\" href=\"https://instructure-uploads.s3.amazonaws.com/account_20960000000000001/attachments/47206723/dp_app.css\"\u003e\u003cp\u003eSee edX Edge for details on what to submit here.\u003c/p\u003e\u003cscript src=\"https://instructure-uploads.s3.amazonaws.com/account_20960000000000001/attachments/47206721/dp_app.js\"\u003e\u003c/script\u003e",
 "due_at":null,
 "unlock_at":null,
 "lock_at":null,
 "points_possible":0.0,
 "grading_type":"points",
 "assignment_group_id":20960000000217785,
 "grading_standard_id":null,
 "created_at":"2021-08-16T13:55:41Z",
 "updated_at":"2021-11-23T17:02:25Z",
 "peer_reviews":true,
 "automatic_peer_reviews":true,
 "position":1,
 "grade_group_students_individually":false,
 "anonymous_peer_reviews":false,
 "group_category_id":null,
 "post_to_sis":false,
 "moderated_grading":false,
 "omit_from_final_grade":false,
 "intra_group_peer_reviews":false,
 "anonymous_instructor_annotations":false,
 "anonymous_grading":false,
 "graders_anonymous_to_graders":false,
 "grader_count":0,
 "grader_comments_visible_to_graders":true,
 "final_grader_id":null,
 "grader_names_visible_to_final_grader":true,
 "allowed_attempts":-1,
 "annotatable_attachment_id":null,
 "hide_in_gradebook":false,
 "secure_params":"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJsdGlfYXNzaWdubWVudF9pZCI6ImYxOTU2Y2Y4LTZlMDgtNGZjYi1hYWRkLTk0MGI3YjhkMDVhNCIsImx0aV9hc3NpZ25tZW50X2Rlc2NyaXB0aW9uIjoiXHUwMDNjcFx1MDAzZVNlZSBlZFggRWRnZSBmb3IgZGV0YWlscyBvbiB3aGF0IHRvIHN1Ym1pdCBoZXJlLlx1MDAzYy9wXHUwMDNlIn0.K58ENiK_-pcZXqqwbPHBPSPPDk7r9ZTZn2JdnKt6Sdw",
 "lti_context_id":"f1956cf8-6e08-4fcb-aadd-940b7b8d05a4",
 "course_id":20960000000210310,
 "name":"Unit 2 Extra Credit Submission: Learning How to Learn",
 "submission_types":["online_text_entry"],
 "has_submitted_submissions":true,
 "due_date_required":false,
 "max_name_length":255,
 "in_closed_grading_period":false,
 "graded_submissions_exist":true,
 "is_quiz_assignment":false,
 "can_duplicate":true,
 "original_course_id":null,
 "original_assignment_id":null,
 "original_lti_resource_link_id":null,
 "original_assignment_name":null,
 "original_quiz_id":null,
 "workflow_state":"published",
 "important_dates":false,
 "muted":true,
 "html_url":"https://canvas.instructure.com/courses/20960000000210310/assignments/2096~853302",
 "peer_review_count":0,
 "peer_reviews_assign_at":null,
 "published":true,
 "only_visible_to_overrides":false,
 "visible_to_everyone":true,
 "locked_for_user":false,
 "submissions_download_url":"https://canvas.instructure.com/courses/2096~210310/assignments/2096~853302/submissions?zip=1",
 "post_manually":false,
 "anonymize_students":false,
 "require_lockdown_browser":false,
 "restrict_quantitative_data":false}
 */

struct Assignment: Codable {
    let id: Int
    let description: String?
    let dueAt: String?
    let unlockAt: String?
    let lockAt: String?
    let pointsPossible: Double?
    let gradingType: String?
    let assignmentGroupId: Int
    let gradingStandardId: Int?
    let createdAt: String?
    let updatedAt: String?
    let peerReviews: Bool?
    let automaticPeerReviews: Bool?
    let position: Int?
    let gradeGroupStudentsIndividually: Bool?
    let anonymousPeerReviews: Bool?
    let groupCategoryId: Int?
    let postToSis: Bool?
    let moderatedGrading: Bool?
    let omitFromFinalGrade: Bool?
    let intraGroupPeerReviews: Bool?
    let anonymousInstructorAnnotations: Bool?
    let anonymousGrading: Bool?
    let gradersAnonymousToGraders: Bool?
    let graderCount: Int?
    let graderCommentsVisibleToGraders: Bool?
    let finalGraderId: Int?
    let graderNamesVisibleToFinalGrader: Bool?
    let allowedAttempts: Int?
    let annotatableAttachmentId: Int?
    let hideInGradebook: Bool?
    let secureParams: String?
    let ltiContextId: String?
    let courseId: Int?
    let name: String
    let submissionTypes: [String]?
    let hasSubmittedSubmissions: Bool?
    let dueDateRequired: Bool?
    let maxNameLength: Int?
    let inClosedGradingPeriod: Bool?
    let gradedSubmissionsExist: Bool?
    let isQuizAssignment: Bool?
    let canDuplicate: Bool?
    let originalCourseId: Int?
    let originalAssignmentId: Int?
    let originalLtiResourceLinkId: Int?
    let originalAssignmentName: String?
    let originalQuizId: Int?
    let workflowState: String?
    let importantDates: Bool?
    let muted: Bool?
    let htmlUrl: String?
    let peerReviewCount: Int?
    let peerReviewsAssignAt: String?
    let published: Bool?
    let onlyVisibleToOverrides: Bool?
    let visibleToEveryone: Bool?
    let lockedForUser: Bool?
    let submissionsDownloadUrl: String?
    let postManually: Bool?
    let anonymizeStudents: Bool?
    let requireLockdownBrowser: Bool?
    let restrictQuantitativeData: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case description
        case dueAt = "due_at"
        case unlockAt = "unlock_at"
        case lockAt = "lock_at"
        case pointsPossible = "points_possible"
        case gradingType = "grading_type"
        case assignmentGroupId = "assignment_group_id"
        case gradingStandardId = "grading_standard_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case peerReviews = "peer_reviews"
        case automaticPeerReviews = "automatic_peer_reviews"
        case position
        case gradeGroupStudentsIndividually = "grade_group_students_individually"
        case anonymousPeerReviews = "anonymous_peer_reviews"
        case groupCategoryId = "group_category_id"
        case postToSis = "post_to_sis"
        case moderatedGrading = "moderated_grading"
        case omitFromFinalGrade = "omit_from_final_grade"
        case intraGroupPeerReviews = "intra_group_peer_reviews"
        case anonymousInstructorAnnotations = "anonymous_instructor_annotations"
        case anonymousGrading = "anonymous_grading"
        case gradersAnonymousToGraders = "graders_anonymous_to_graders"
        case graderCount = "grader_count"
        case graderCommentsVisibleToGraders = "grader_comments_visible_to_graders"
        case finalGraderId = "final_grader_id"
        case graderNamesVisibleToFinalGrader = "grader_names_visible_to_final_grader"
        case allowedAttempts = "allowed_attempts"
        case annotatableAttachmentId = "annotatable_attachment_id"
        case hideInGradebook = "hide_in_gradebook"
        case secureParams = "secure_params"
        case ltiContextId = "lti_context_id"
        case courseId = "course_id"
        case name
        case submissionTypes = "submission_types"
        case hasSubmittedSubmissions = "has_submitted_submissions"
        case dueDateRequired = "due_date_required"
        case maxNameLength = "max_name_length"
        case inClosedGradingPeriod = "in_closed_grading_period"
        case gradedSubmissionsExist = "graded_submissions_exist"
        case isQuizAssignment = "is_quiz_assignment"
        case canDuplicate = "can_duplicate"
        case originalCourseId = "original_course_id"
        case originalAssignmentId = "original_assignment_id"
        case originalLtiResourceLinkId = "original_lti_resource_link_id"
        case originalAssignmentName = "original_assignment_name"
        case originalQuizId = "original_quiz_id"
        case workflowState = "workflow_state"
        case importantDates = "important_dates"
        case muted
        case htmlUrl = "html_url"
        case peerReviewCount = "peer_review_count"
        case peerReviewsAssignAt = "peer_reviews_assign_at"
        case published
        case onlyVisibleToOverrides = "only_visible_to_overrides"
        case visibleToEveryone = "visible_to_everyone"
        case lockedForUser = "locked_for_user"
        case submissionsDownloadUrl = "submissions_download_url"
        case postManually = "post_manually"
        case anonymizeStudents = "anonymize_students"
        case requireLockdownBrowser = "require_lockdown_browser"
        case restrictQuantitativeData = "restrict_quantitative_data"
    }
}
