//
//  AssignmentAPI.swift
//  CanvasPlusPlayground
//
//  Created by Sankaet Cheemalamarri on 9/14/24.
//

import Foundation

// https://canvas.instructure.com/doc/api/assignments.html
// https://github.com/instructure/canvas-ios/blob/49a3e347116d623638c66b7adbcc946294faa212/Core/Core/Assignments/APIAssignment.swift
struct AssignmentAPI: APIResponse {
    typealias Model = NoOpCacheable

    // swiftlint:disable identifier_name
    let id: Int
    let description: String?
    let due_at: String?
    let unlock_at: String?
    let lock_at: String?
    let points_possible: Double?
    let grading_type: String?
    let assignment_group_id: Int
    let grading_standard_id: Int?
    let created_at: String?
    let updated_at: String?
    let peer_reviews: Bool?
    let automatic_peer_reviews: Bool?
    let position: Int?
    let grade_group_students_individually: Bool?
    let anonymous_peer_reviews: Bool?
    let group_category_id: Int?
    let post_to_sis: Bool?
    let moderated_grading: Bool?
    let omit_from_final_grade: Bool?
    let intra_group_peer_reviews: Bool?
    let anonymous_instructor_annotations: Bool?
    let anonymous_grading: Bool?
    let graders_anonymous_to_graders: Bool?
    let grader_count: Int?
    let grader_comments_visible_to_graders: Bool?
    let final_grader_id: Int?
    let grader_names_visible_to_final_grader: Bool?
    let allowed_attempts: Int?
    let annotatable_attachment_id: Int?
    let hide_in_gradebook: Bool?
    let secure_params: String?
    let lti_context_id: String?
    let course_id: Int?
    let name: String
    let submission_types: [String]?
    let has_submitted_submissions: Bool?
    let due_date_required: Bool?
    let max_name_length: Int?
    let in_closed_grading_period: Bool?
    let graded_submissions_exist: Bool?
    let is_quiz_assignment: Bool?
    let can_duplicate: Bool?
    let original_course_id: Int?
    let original_assignment_id: Int?
    let original_lti_resource_link_id: String?
    let original_assignment_name: String?
    let original_quiz_id: Int?
    let workflow_state: String?
    let important_dates: Bool?
    let muted: Bool?
    let html_url: String?
    let peer_review_count: Int?
    let peer_reviews_assign_at: String?
    let published: Bool?
    let only_visible_to_overrides: Bool?
    let visible_to_everyone: Bool?
    let locked_for_user: Bool?
    let submissions_download_url: String?
    let post_manually: Bool?
    let anonymize_students: Bool?
    let require_lockdown_browser: Bool?
    let restrict_quantitative_data: Bool?
    let submission: SubmissionAPI?
    // swiftlint:enable identifier_name
}
