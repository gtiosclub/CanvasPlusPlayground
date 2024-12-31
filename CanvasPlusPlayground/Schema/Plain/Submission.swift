//
//  Submission.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/18/24.
//

import Foundation

struct Submission: Codable {
    let assignmentID: Int?
    let assignment: String?
    let course: String?
    let attempt: Int?
    let body: String?
    let grade: String?
    let gradeMatchesCurrentSubmission: Bool?
    let htmlURL: URL?
    let previewURL: URL?
    let score: Double?
    let submissionComments: String?
    let submissionType: String?
    let submittedAt: String?
    let url: String?
    let userID: Int?
    let graderID: Int?
    let gradedAt: String?
    let user: String?
    let late: Bool?
    let assignmentVisible: Bool?
    let excused: Bool?
    let missing: Bool?
    let latePolicyStatus: String?
    let pointsDeducted: Double?
    let secondsLate: Int?
    let workflowState: WorkflowState?
    let extraAttempts: Int?
    let anonymousID: String?
    let postedAt: String?
    let readStatus: String?
    let redoRequest: Bool?

    enum CodingKeys: String, CodingKey {
        case assignmentID = "assignment_id"
        case assignment
        case course
        case attempt
        case body
        case grade
        case gradeMatchesCurrentSubmission = "grade_matches_current_submission"
        case htmlURL = "html_url"
        case previewURL = "preview_url"
        case score
        case submissionComments = "submission_comments"
        case submissionType = "submission_type"
        case submittedAt = "submitted_at"
        case url
        case userID = "user_id"
        case graderID = "grader_id"
        case gradedAt = "graded_at"
        case user
        case late
        case assignmentVisible = "assignment_visible"
        case excused
        case missing
        case latePolicyStatus = "late_policy_status"
        case pointsDeducted = "points_deducted"
        case secondsLate = "seconds_late"
        case workflowState = "workflow_state"
        case extraAttempts = "extra_attempts"
        case anonymousID = "anonymous_id"
        case postedAt = "posted_at"
        case readStatus = "read_status"
        case redoRequest = "redo_request"
    }

    enum WorkflowState: String, Codable {
        case submitted
        case unsubmitted
        case graded
        case pendingReview = "pending_review"
    }
}

/*
{
  // The submission's assignment id
  "assignment_id": 23,
  // The submission's assignment (see the assignments API) (optional)
  "assignment": null,
  // The submission's course (see the course API) (optional)
  "course": null,
  // This is the submission attempt number.
  "attempt": 1,
  // The content of the submission, if it was submitted directly in a text field.
  "body": "There are three factors too...",
  // The grade for the submission, translated into the assignment grading scheme
  // (so a letter grade, for example).
  "grade": "A-",
  // A boolean flag which is false if the student has re-submitted since the
  // submission was last graded.
  "grade_matches_current_submission": true,
  // URL to the submission. This will require the user to log in.
  "html_url": "http://example.com/courses/255/assignments/543/submissions/134",
  // URL to the submission preview. This will require the user to log in.
  "preview_url": "http://example.com/courses/255/assignments/543/submissions/134?preview=1",
  // The raw score
  "score": 13.5,
  // Associated comments for a submission (optional)
  "submission_comments": null,
  // The types of submission ex:
  // ('online_text_entry'|'online_url'|'online_upload'|'online_quiz'|'media_record
  // ing'|'student_annotation')
  "submission_type": "online_text_entry",
  // The timestamp when the assignment was submitted
  "submitted_at": "2012-01-01T01:00:00Z",
  // The URL of the submission (for 'online_url' submissions).
  "url": null,
  // The id of the user who created the submission
  "user_id": 134,
  // The id of the user who graded the submission. This will be null for
  // submissions that haven't been graded yet. It will be a positive number if a
  // real user has graded the submission and a negative number if the submission
  // was graded by a process (e.g. Quiz autograder and autograding LTI tools).
  // Specifically autograded quizzes set grader_id to the negative of the quiz id.
  // Submissions autograded by LTI tools set grader_id to the negative of the tool
  // id.
  "grader_id": 86,
  "graded_at": "2012-01-02T03:05:34Z",
  // The submissions user (see user API) (optional)
  "user": null,
  // Whether the submission was made after the applicable due date
  "late": false,
  // Whether the assignment is visible to the user who submitted the assignment.
  // Submissions where `assignment_visible` is false no longer count towards the
  // student's grade and the assignment can no longer be accessed by the student.
  // `assignment_visible` becomes false for submissions that do not have a grade
  // and whose assignment is no longer assigned to the student's section.
  "assignment_visible": true,
  // Whether the assignment is excused.  Excused assignments have no impact on a
  // user's grade.
  "excused": true,
  // Whether the assignment is missing.
  "missing": true,
  // The status of the submission in relation to the late policy. Can be late,
  // missing, extended, none, or null.
  "late_policy_status": "missing",
  // The amount of points automatically deducted from the score by the
  // missing/late policy for a late or missing assignment.
  "points_deducted": 12.3,
  // The amount of time, in seconds, that an submission is late by.
  "seconds_late": 300,
  // The current state of the submission
  "workflow_state": "submitted",
  // Extra submission attempts allowed for the given user and assignment.
  "extra_attempts": 10,
  // A unique short ID identifying this submission without reference to the owning
  // user. Only included if the caller has administrator access for the current
  // account.
  "anonymous_id": "acJ4Q",
  // The date this submission was posted to the student, or nil if it has not been
  // posted.
  "posted_at": "2020-01-02T11:10:30Z",
  // The read status of this submission for the given user (optional). Including
  // read_status will mark submission(s) as read.
  "read_status": "read",
  // This indicates whether the submission has been reassigned by the instructor.
  "redo_request": true
}
*/
