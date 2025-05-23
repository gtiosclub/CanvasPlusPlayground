//
//  Assignment.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 2/21/25.
//

import Foundation
import SwiftData

typealias Assignment = CanvasSchemaV1.Assignment

extension CanvasSchemaV1 {
    @Model
    class Assignment {
        typealias ID = String
        typealias ServerID = Int

        @Attribute(.unique) let id: String
        var name: String
        var assignmentGroupId: Int
        var assignmentDescription: String? /// originally `description` in AssignmentAPI
        var dueAt: String?
        var unlockAt: String?
        var lockAt: String?
        var pointsPossible: Double?
        var gradingType: GradingType?
        var gradingStandardId: Int?
        var createdAt: String?
        var updatedAt: String?
        var peerReviews: Bool?
        var automaticPeerReviews: Bool?
        var position: Int?
        var gradeGroupStudentsIndividually: Bool?
        var anonymousPeerReviews: Bool?
        var groupCategoryId: Int?
        var postToSis: Bool?
        var moderatedGrading: Bool?
        var omitFromFinalGrade: Bool?
        var intraGroupPeerReviews: Bool?
        var anonymousInstructorAnnotations: Bool?
        var anonymousGrading: Bool?
        var gradersAnonymousToGraders: Bool?
        var graderCount: Int?
        var graderCommentsVisibleToGraders: Bool?
        var finalGraderId: Int?
        var graderNamesVisibleToFinalGrader: Bool?
        var allowedAttempts: Int?
        var annotatableAttachmentId: Int?
        var hideInGradebook: Bool?
        var secureParams: String?
        var ltiContextId: String?
        var courseId: Int?
        var submissionTypes: [SubmissionType]?
        /// If true, the assignment has been submitted to by at least one student
        var hasSubmittedSubmissions: Bool?
        var dueDateRequired: Bool?
        var maxNameLength: Int?
        var inClosedGradingPeriod: Bool?
        var gradedSubmissionsExist: Bool?
        var isQuizAssignment: Bool?
        var canDuplicate: Bool?
        var originalCourseId: Int?
        var originalAssignmentId: Int?
        var originalLtiResourceLinkId: String?
        var originalAssignmentName: String?
        var originalQuizId: Int?
        var workflowState: String?
        var importantDates: Bool?
        var muted: Bool?
        var htmlUrl: String?
        var peerReviewCount: Int?
        var peerReviewsAssignAt: String?
        var published: Bool?
        var onlyVisibleToOverrides: Bool?
        var visibleToEveryone: Bool?
        var lockedForUser: Bool?
        var submissionsDownloadUrl: String?
        var postManually: Bool?
        var anonymizeStudents: Bool?
        var requireLockdownBrowser: Bool?
        var restrictQuantitativeData: Bool?
        var allowedExtensions: [String]?
        var submission: SubmissionAPI?
        var canSubmit: Bool?
        // MARK: Custom Properties
        var dueDate: Date? {
            ISO8601DateFormatter().date(from: dueAt ?? "2024-12-12T19:06:20Z")
        }

        var unlockDate: Date? {
            ISO8601DateFormatter().date(from: unlockAt ?? "2024-12-12T19:06:20Z")
        }

        var lockDate: Date? {
            ISO8601DateFormatter().date(from: lockAt ?? "2024-12-12T19:06:20Z")
        }

        var isLocked: Bool {
            guard let unlockDate else { return false }

            return unlockDate > Date()
        }

        var isOnlineQuiz: Bool {
            submissionTypes?.contains(.onlineQuiz) ?? false
        }

        var formattedPointsPossible: String {
            guard let points = pointsPossible else { return "--" }
            return points.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", points) : String(points)
        }

        var formattedGrade: String {
            guard let submissionGrade = submission?.grade,
                  let gradeDouble = Double(submissionGrade) else {
                return submission?.grade ?? "--"
            }
            return gradeDouble.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", gradeDouble) : String(gradeDouble)
        }

        // swiftlint:disable:next function_body_length
        init(from assignmentAPI: AssignmentAPI) {
            self.id = assignmentAPI.id.asString
            self.name = assignmentAPI.name
            self.assignmentGroupId = assignmentAPI.assignment_group_id
            self.assignmentDescription = assignmentAPI.description
            self.dueAt = assignmentAPI.due_at
            self.unlockAt = assignmentAPI.unlock_at
            self.lockAt = assignmentAPI.lock_at
            self.pointsPossible = assignmentAPI.points_possible
            self.gradingType = GradingType(rawValue: assignmentAPI.grading_type ?? "")
            self.gradingStandardId = assignmentAPI.grading_standard_id
            self.createdAt = assignmentAPI.created_at
            self.updatedAt = assignmentAPI.updated_at
            self.peerReviews = assignmentAPI.peer_reviews
            self.automaticPeerReviews = assignmentAPI.automatic_peer_reviews
            self.position = assignmentAPI.position
            self.gradeGroupStudentsIndividually = assignmentAPI.grade_group_students_individually
            self.anonymousPeerReviews = assignmentAPI.anonymous_peer_reviews
            self.groupCategoryId = assignmentAPI.group_category_id
            self.postToSis = assignmentAPI.post_to_sis
            self.moderatedGrading = assignmentAPI.moderated_grading
            self.omitFromFinalGrade = assignmentAPI.omit_from_final_grade
            self.intraGroupPeerReviews = assignmentAPI.intra_group_peer_reviews
            self.anonymousInstructorAnnotations = assignmentAPI.anonymous_instructor_annotations
            self.anonymousGrading = assignmentAPI.anonymous_grading
            self.gradersAnonymousToGraders = assignmentAPI.graders_anonymous_to_graders
            self.graderCount = assignmentAPI.grader_count
            self.graderCommentsVisibleToGraders = assignmentAPI.grader_comments_visible_to_graders
            self.finalGraderId = assignmentAPI.final_grader_id
            self.graderNamesVisibleToFinalGrader = assignmentAPI.grader_names_visible_to_final_grader
            self.allowedAttempts = assignmentAPI.allowed_attempts
            self.annotatableAttachmentId = assignmentAPI.annotatable_attachment_id
            self.hideInGradebook = assignmentAPI.hide_in_gradebook
            self.secureParams = assignmentAPI.secure_params
            self.ltiContextId = assignmentAPI.lti_context_id
            self.courseId = assignmentAPI.course_id
            self.submissionTypes = assignmentAPI.submission_types?.compactMap { SubmissionType(rawValue: $0) }
            self.hasSubmittedSubmissions = assignmentAPI.has_submitted_submissions
            self.dueDateRequired = assignmentAPI.due_date_required
            self.maxNameLength = assignmentAPI.max_name_length
            self.inClosedGradingPeriod = assignmentAPI.in_closed_grading_period
            self.gradedSubmissionsExist = assignmentAPI.graded_submissions_exist
            self.isQuizAssignment = assignmentAPI.is_quiz_assignment
            self.canDuplicate = assignmentAPI.can_duplicate
            self.originalCourseId = assignmentAPI.original_course_id
            self.originalAssignmentId = assignmentAPI.original_assignment_id
            self.originalLtiResourceLinkId = assignmentAPI.original_lti_resource_link_id
            self.originalAssignmentName = assignmentAPI.original_assignment_name
            self.originalQuizId = assignmentAPI.original_quiz_id
            self.workflowState = assignmentAPI.workflow_state
            self.importantDates = assignmentAPI.important_dates
            self.muted = assignmentAPI.muted
            self.htmlUrl = assignmentAPI.html_url
            self.peerReviewCount = assignmentAPI.peer_review_count
            self.peerReviewsAssignAt = assignmentAPI.peer_reviews_assign_at
            self.published = assignmentAPI.published
            self.onlyVisibleToOverrides = assignmentAPI.only_visible_to_overrides
            self.visibleToEveryone = assignmentAPI.visible_to_everyone
            self.lockedForUser = assignmentAPI.locked_for_user
            self.submissionsDownloadUrl = assignmentAPI.submissions_download_url
            self.postManually = assignmentAPI.post_manually
            self.anonymizeStudents = assignmentAPI.anonymize_students
            self.requireLockdownBrowser = assignmentAPI.require_lockdown_browser
            self.restrictQuantitativeData = assignmentAPI.restrict_quantitative_data
            self.allowedExtensions = assignmentAPI.allowed_extensions
            self.submission = assignmentAPI.submission
            self.canSubmit = assignmentAPI.can_submit
        }

        enum GradingType: String, Codable {
            case passFail = "pass_fail"
            case percent = "percent"
            case letterGrade = "letter_grade"
            case gpaScale = "gpa_scale"
            case points = "points"
        }

        static let example = Assignment(from: .example)
    }
}

extension Assignment: Cacheable {
    func merge(with other: Assignment) {
        self.name = other.name
        self.assignmentGroupId = other.assignmentGroupId
        self.assignmentDescription = other.assignmentDescription
        self.dueAt = other.dueAt
        self.unlockAt = other.unlockAt
        self.lockAt = other.lockAt
        self.pointsPossible = other.pointsPossible
        self.gradingType = other.gradingType
        self.gradingStandardId = other.gradingStandardId
        self.createdAt = other.createdAt
        self.updatedAt = other.updatedAt
        self.peerReviews = other.peerReviews
        self.automaticPeerReviews = other.automaticPeerReviews
        self.position = other.position
        self.gradeGroupStudentsIndividually = other.gradeGroupStudentsIndividually
        self.anonymousPeerReviews = other.anonymousPeerReviews
        self.groupCategoryId = other.groupCategoryId
        self.postToSis = other.postToSis
        self.moderatedGrading = other.moderatedGrading
        self.omitFromFinalGrade = other.omitFromFinalGrade
        self.intraGroupPeerReviews = other.intraGroupPeerReviews
        self.anonymousInstructorAnnotations = other.anonymousInstructorAnnotations
        self.anonymousGrading = other.anonymousGrading
        self.gradersAnonymousToGraders = other.gradersAnonymousToGraders
        self.graderCount = other.graderCount
        self.graderCommentsVisibleToGraders = other.graderCommentsVisibleToGraders
        self.finalGraderId = other.finalGraderId
        self.graderNamesVisibleToFinalGrader = other.graderNamesVisibleToFinalGrader
        self.allowedAttempts = other.allowedAttempts
        self.annotatableAttachmentId = other.annotatableAttachmentId
        self.hideInGradebook = other.hideInGradebook
        self.secureParams = other.secureParams
        self.ltiContextId = other.ltiContextId
        self.courseId = other.courseId
        self.submissionTypes = other.submissionTypes
        self.hasSubmittedSubmissions = other.hasSubmittedSubmissions
        self.dueDateRequired = other.dueDateRequired
        self.maxNameLength = other.maxNameLength
        self.inClosedGradingPeriod = other.inClosedGradingPeriod
        self.gradedSubmissionsExist = other.gradedSubmissionsExist
        self.isQuizAssignment = other.isQuizAssignment
        self.canDuplicate = other.canDuplicate
        self.originalCourseId = other.originalCourseId
        self.originalAssignmentId = other.originalAssignmentId
        self.originalLtiResourceLinkId = other.originalLtiResourceLinkId
        self.originalAssignmentName = other.originalAssignmentName
        self.originalQuizId = other.originalQuizId
        self.workflowState = other.workflowState
        self.importantDates = other.importantDates
        self.muted = other.muted
        self.htmlUrl = other.htmlUrl
        self.peerReviewCount = other.peerReviewCount
        self.peerReviewsAssignAt = other.peerReviewsAssignAt
        self.published = other.published
        self.onlyVisibleToOverrides = other.onlyVisibleToOverrides
        self.visibleToEveryone = other.visibleToEveryone
        self.lockedForUser = other.lockedForUser
        self.submissionsDownloadUrl = other.submissionsDownloadUrl
        self.postManually = other.postManually
        self.anonymizeStudents = other.anonymizeStudents
        self.requireLockdownBrowser = other.requireLockdownBrowser
        self.restrictQuantitativeData = other.restrictQuantitativeData
        self.allowedExtensions = other.allowedExtensions
        self.submission = other.submission
        self.canSubmit = other.canSubmit
    }

}

enum SubmissionType: String, Codable {
    case discussionTopic = "discussion_topic"
    case onlineQuiz = "online_quiz"
    case onPaper = "on_paper"
    case none = "none"
    case externalTool = "external_tool"
    case onlineTextEntry = "online_text_entry"
    case onlineUrl = "online_url"
    case onlineUpload = "online_upload"
    case mediaRecording = "media_recording"
    case studentAnnotation = "student_annotation"

    var displayName: String {
        rawValue
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}
