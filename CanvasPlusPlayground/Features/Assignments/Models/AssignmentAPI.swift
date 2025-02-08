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
    var id: Int
    var description: String?
    var due_at: String?
    var unlock_at: String?
    var lock_at: String?
    var points_possible: Double?
    var grading_type: String?
    var assignment_group_id: Int
    var grading_standard_id: Int?
    var created_at: String?
    var updated_at: String?
    var peer_reviews: Bool?
    var automatic_peer_reviews: Bool?
    var position: Int?
    var grade_group_students_individually: Bool?
    var anonymous_peer_reviews: Bool?
    var group_category_id: Int?
    var post_to_sis: Bool?
    var moderated_grading: Bool?
    var omit_from_final_grade: Bool?
    var intra_group_peer_reviews: Bool?
    var anonymous_instructor_annotations: Bool?
    var anonymous_grading: Bool?
    var graders_anonymous_to_graders: Bool?
    var grader_count: Int?
    var grader_comments_visible_to_graders: Bool?
    var final_grader_id: Int?
    var grader_names_visible_to_final_grader: Bool?
    var allowed_attempts: Int?
    var annotatable_attachment_id: Int?
    var hide_in_gradebook: Bool?
    var secure_params: String?
    var lti_context_id: String?
    var course_id: Int?
    var name: String
    var submission_types: [String]?
    var has_submitted_submissions: Bool?
    var due_date_required: Bool?
    var max_name_length: Int?
    var in_closed_grading_period: Bool?
    var graded_submissions_exist: Bool?
    var is_quiz_assignment: Bool?
    var can_duplicate: Bool?
    var original_course_id: Int?
    var original_assignment_id: Int?
    var original_lti_resource_link_id: String?
    var original_assignment_name: String?
    var original_quiz_id: Int?
    var workflow_state: String?
    var important_dates: Bool?
    var muted: Bool?
    var html_url: String?
    var peer_review_count: Int?
    var peer_reviews_assign_at: String?
    var published: Bool?
    var only_visible_to_overrides: Bool?
    var visible_to_everyone: Bool?
    var locked_for_user: Bool?
    var submissions_download_url: String?
    var post_manually: Bool?
    var anonymize_students: Bool?
    var require_lockdown_browser: Bool?
    var restrict_quantitative_data: Bool?
    var submission: SubmissionAPI?
    // swiftlint:enable identifier_name
    init(id: Int, name: String, groupID: Int) {
        self.id = id
        self.name = name
        self.assignment_group_id = groupID
    }

    var dueDate: Date? {
        ISO8601DateFormatter().date(from: due_at ?? "2024-12-12T19:06:20Z")
    }

    var submissionTypes:[String] {
        submission_types ?? []
    }
    static let example: AssignmentAPI = AssignmentAPI(id: 5, name: "example", groupID: 5)
}
