//
//  AssignmentAPI.swift
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

struct AssignmentAPI: APIResponse {
    typealias Model = NoOpCacheable
    
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
}
