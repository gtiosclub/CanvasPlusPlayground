//
//  Submission.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/31/24.
//

import Foundation
import SwiftData

@Model
class Submission: Cacheable {
    typealias ServerID = Int

    @Attribute(.unique) let id: String

    var assignmentId: Int
    var assignment: String?
    var course: String?
    var attempt: Int?
    var body: String?
    var grade: String?
    var gradeMatchesCurrentSubmission: Bool?
    var htmlUrl: URL?
    var previewUrl: URL?
    var score: Double?
    var submissionComments: String?
    var submissionType: String?
    var submittedAt: String?
    var url: String?
    var userId: Int
    var graderId: Int?
    var gradedAt: String?
    var user: String?
    var late: Bool?
    var assignmentVisible: Bool?
    var excused: Bool?
    var missing: Bool?
    var latePolicyStatus: String?
    var pointsDeducted: Double?
    var secondsLate: Int?
    var workflowState: WorkflowState?
    var extraAttempts: Int?
    var anonymousId: String?
    var postedAt: String?
    var readStatus: String?
    var redoRequest: Bool?

    init(from submissionAPI: SubmissionAPI) {
        self.id = submissionAPI.id
        self.assignmentId = submissionAPI.assignment_id
        self.assignment = submissionAPI.assignment
        self.course = submissionAPI.course
        self.attempt = submissionAPI.attempt
        self.body = submissionAPI.body
        self.grade = submissionAPI.grade
        self.gradeMatchesCurrentSubmission = submissionAPI.grade_matches_current_submission
        self.htmlUrl = submissionAPI.html_url
        self.previewUrl = submissionAPI.preview_url
        self.score = submissionAPI.score
        self.submissionComments = submissionAPI.submission_comments
        self.submissionType = submissionAPI.submission_type
        self.submittedAt = submissionAPI.submitted_at
        self.url = submissionAPI.url
        self.userId = submissionAPI.user_id
        self.graderId = submissionAPI.grader_id
        self.gradedAt = submissionAPI.graded_at
        self.user = submissionAPI.user
        self.late = submissionAPI.late
        self.assignmentVisible = submissionAPI.assignment_visible
        self.excused = submissionAPI.excused
        self.missing = submissionAPI.missing
        self.latePolicyStatus = submissionAPI.late_policy_status
        self.pointsDeducted = submissionAPI.points_deducted
        self.secondsLate = submissionAPI.seconds_late
        if let workflowState = submissionAPI.workflow_state {
            self.workflowState = WorkflowState(
                rawValue: workflowState
            )
        }
        self.extraAttempts = submissionAPI.extra_attempts
        self.anonymousId = submissionAPI.anonymous_id
        self.postedAt = submissionAPI.posted_at
        self.readStatus = submissionAPI.read_status
        self.redoRequest = submissionAPI.redo_request
    }

    func merge(with other: Submission) {
        self.assignmentId = other.assignmentId
        self.assignment = other.assignment
        self.course = other.course
        self.attempt = other.attempt
        self.body = other.body
        self.grade = other.grade
        self.gradeMatchesCurrentSubmission = other.gradeMatchesCurrentSubmission
        self.htmlUrl = other.htmlUrl
        self.previewUrl = other.previewUrl
        self.score = other.score
        self.submissionComments = other.submissionComments
        self.submissionType = other.submissionType
        self.submittedAt = other.submittedAt
        self.url = other.url
        self.userId = other.userId
        self.graderId = other.graderId
        self.gradedAt = other.gradedAt
        self.user = other.user
        self.late = other.late
        self.assignmentVisible = other.assignmentVisible
        self.excused = other.excused
        self.missing = other.missing
        self.latePolicyStatus = other.latePolicyStatus
        self.pointsDeducted = other.pointsDeducted
        self.secondsLate = other.secondsLate
        self.workflowState = other.workflowState
        self.extraAttempts = other.extraAttempts
        self.anonymousId = other.anonymousId
        self.postedAt = other.postedAt
        self.readStatus = other.readStatus
        self.redoRequest = other.redoRequest
    }

    enum WorkflowState: String, Codable {
        case submitted
        case unsubmitted
        case graded
        case pendingReview = "pending_review"

        var displayValue: String {
            switch self {
            case .submitted:
                return "Submitted"
            case .unsubmitted:
                return "Unsubmitted"
            case .graded:
                return "Graded"
            case .pendingReview:
                return "Pending Review"
            }
        }
    }
}
