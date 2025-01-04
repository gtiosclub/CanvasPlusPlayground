//
//  Quiz.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/14/24.
//

import Foundation
import SwiftData

@Model
class Quiz {

    @Attribute(.unique) let id: String
    var courseID: String

    var accessCode: String?
    var allDates: Set<APIAssignmentDate>
    var allowedAttempts: Int
    var assignmentID: String?
    var cantGoBack: Bool
    var details: String?
    var dueAt: Date?
    var hasAccessCode: Bool
    var hideCorrectAnswersAt: Date?
    var hideResultsRaw: String?
    var htmlURL: URL?
    var ipFilter: String?
    var lockAt: Date?
    var lockExplanation: String?
    var lockedForUser: Bool
    var mobileURL: URL?
    var oneQuestionAtATime: Bool
    // var order: String?
    var orderDate: Date?
    var pointsPossible: Double?
    var published: Bool
    var questionCount: Int?
    var questionTypes: [QuizQuestionType]
    var quizTypeOrder: Int
    var quizTypeRaw: String
    var requireLockdownBrowser: Bool
    var requireLockdownBrowserForResults: Bool
    var scoringPolicyRaw: String?
    var showCorrectAnswers: Bool
    var showCorrectAnswersAt: Date?
    var showCorrectAnswersLastAttempt: Bool
    var shuffleAnswers: Bool
    var submission: APIQuizSubmission?
    var timeLimit: Double? // minutes
    var title: String
    var unlockAt: Date?
    var unpublishable: Bool
    var anonymousSubmissions: Bool

    var hideResults: QuizHideResults? {
        get { return hideResultsRaw.flatMap { QuizHideResults(rawValue: $0) } }
        set { hideResultsRaw = newValue?.rawValue }
    }

    var quizType: QuizType {
        get { return QuizType(rawValue: quizTypeRaw) ?? .assignment }
        set { quizTypeRaw = newValue.rawValue }
    }

    var scoringPolicy: ScoringPolicy? {
        get { return scoringPolicyRaw.flatMap { ScoringPolicy(rawValue: $0) } }
        set { scoringPolicyRaw = newValue?.rawValue }
    }

    init(api: QuizAPI) {
        self.id = api.id.asString
        self.courseID = ""
        self.accessCode = api.access_code

        if let dates = api.all_dates { self.allDates = Set(dates) } else { self.allDates = [] }

        self.allowedAttempts = api.allowed_attempts ?? 0
        self.assignmentID = api.assignment_id?.asString
        self.cantGoBack = api.cant_go_back ?? false
        self.details = api.description
        self.dueAt = api.due_at
        self.hasAccessCode = api.has_access_code ?? false
        self.hideCorrectAnswersAt = api.hide_correct_answers_at
        self.htmlURL = api.html_url
        self.id = api.id.asString
        self.ipFilter = api.ip_filter
        self.lockAt = api.lock_at
        self.lockExplanation = api.lock_explanation
        self.lockedForUser = api.locked_for_user ?? false
        self.mobileURL = api.mobile_url
        self.oneQuestionAtATime = api.one_question_at_a_time ?? false
        self.pointsPossible = api.points_possible
        self.published = api.published == true
        self.questionCount = api.question_count

        self.quizTypeOrder = QuizType.allCases.firstIndex(of: api.quiz_type) ?? QuizType.allCases.count
        self.requireLockdownBrowser = api.require_lockdown_browser
        self.requireLockdownBrowserForResults = api.require_lockdown_browser_for_results
        self.showCorrectAnswers = api.show_correct_answers == true
        self.showCorrectAnswersAt = api.show_correct_answers_at
        self.showCorrectAnswersLastAttempt = api.show_correct_answers_last_attempt == true
        self.shuffleAnswers = api.shuffle_answers ?? false
        self.timeLimit = api.time_limit
        self.title = api.title
        self.unlockAt = api.unlock_at
        self.unpublishable = api.unpublishable == true
        let orderDate = (api.quiz_type == .assignment ? api.due_at : api.lock_at) ?? Date.distantFuture
        self.orderDate = orderDate
        // self.order = ISO8601DateFormatter.string(from: orderDate, timeZone: TimeZone(abbreviation: "UTC")!, formatOptions: .withInternetDateTime)
        self.anonymousSubmissions = api.anonymous_submissions ?? false

        self.questionTypes = api.question_types ?? []
        self.hideResultsRaw = api.hide_results?.rawValue
        self.quizTypeRaw = api.quiz_type.rawValue
        self.scoringPolicyRaw = api.scoring_policy?.rawValue
    }
}

// MARK: Cacheable

extension Quiz: Cacheable {
    typealias ServerID = Int

    func merge(with other: Quiz) {
        self.accessCode = other.accessCode
        self.allDates = other.allDates
        self.allowedAttempts = other.allowedAttempts
        self.assignmentID = other.assignmentID
        self.cantGoBack = other.cantGoBack
        self.courseID = other.courseID
        self.details = other.details
        self.dueAt = other.dueAt
        self.hasAccessCode = other.hasAccessCode
        self.hideCorrectAnswersAt = other.hideCorrectAnswersAt
        self.hideResultsRaw = other.hideResultsRaw
        self.htmlURL = other.htmlURL
        self.ipFilter = other.ipFilter
        self.lockAt = other.lockAt
        self.lockExplanation = other.lockExplanation
        self.lockedForUser = other.lockedForUser
        self.mobileURL = other.mobileURL
        self.oneQuestionAtATime = other.oneQuestionAtATime
        self.orderDate = other.orderDate
        self.pointsPossible = other.pointsPossible
        self.published = other.published
        self.questionCount = other.questionCount
        self.questionTypes = other.questionTypes
        self.quizTypeOrder = other.quizTypeOrder
        self.quizTypeRaw = other.quizTypeRaw
        self.requireLockdownBrowser = other.requireLockdownBrowser
        self.requireLockdownBrowserForResults = other.requireLockdownBrowserForResults
        self.scoringPolicyRaw = other.scoringPolicyRaw
        self.showCorrectAnswers = other.showCorrectAnswers
        self.showCorrectAnswersAt = other.showCorrectAnswersAt
        self.showCorrectAnswersLastAttempt = other.showCorrectAnswersLastAttempt
        self.shuffleAnswers = other.shuffleAnswers
        self.submission = other.submission
        self.timeLimit = other.timeLimit
        self.title = other.title
        self.unlockAt = other.unlockAt
        self.unpublishable = other.unpublishable
        self.anonymousSubmissions = other.anonymousSubmissions
    }
}

/*
 Quiz {
     id (integer, optional): the ID of the quiz,
     title (string, optional): the title of the quiz,
     html_url (string, optional): the HTTP/HTTPS URL to the quiz,
     mobile_url (string, optional): a url suitable for loading the quiz in a mobile webview. it will persiste the headless session and, for quizzes in public courses, will force the user to login,
     preview_url (string, optional): A url that can be visited in the browser with a POST request to preview a quiz as the teacher. Only present when the user may grade,
     description (string, optional): the description of the quiz,
     quiz_type (string, optional) = ['practice_quiz' or 'assignment' or 'graded_survey' or 'survey']: type of quiz possible values: 'practice_quiz', 'assignment', 'graded_survey', 'survey',
     assignment_group_id (integer, optional): the ID of the quiz's assignment group:,
     time_limit (integer, optional): quiz time limit in minutes,
     shuffle_answers (boolean, optional): shuffle answers for students?,
     hide_results (string, optional) = ['always' or 'until_after_last_attempt']: let students see their quiz responses? possible values: null, 'always', 'until_after_last_attempt',
     show_correct_answers (boolean, optional): show which answers were correct when results are shown? only valid if hide_results=null,
     show_correct_answers_last_attempt (boolean, optional): restrict the show_correct_answers option above to apply only to the last submitted attempt of a quiz that allows multiple attempts. only valid if show_correct_answers=true and allowed_attempts > 1,
     show_correct_answers_at (datetime, optional): when should the correct answers be visible by students? only valid if show_correct_answers=true,
     hide_correct_answers_at (datetime, optional): prevent the students from seeing correct answers after the specified date has passed. only valid if show_correct_answers=true,
     one_time_results (boolean, optional): prevent the students from seeing their results more than once (right after they submit the quiz),
     scoring_policy (string, optional) = ['keep_highest' or 'keep_latest']: which quiz score to keep (only if allowed_attempts != 1) possible values: 'keep_highest', 'keep_latest',
     allowed_attempts (integer, optional): how many times a student can take the quiz -1 = unlimited attempts,
     one_question_at_a_time (boolean, optional): show one question at a time?,
     question_count (integer, optional): the number of questions in the quiz,
     points_possible (integer, optional): The total point value given to the quiz,
     cant_go_back (boolean, optional): lock questions after answering? only valid if one_question_at_a_time=true,
     access_code (string, optional): access code to restrict quiz access,
     ip_filter (string, optional): IP address or range that quiz access is limited to,
     due_at (datetime, optional): when the quiz is due,
     lock_at (datetime, optional): when to lock the quiz,
     unlock_at (datetime, optional): when to unlock the quiz,
     published (boolean, optional): whether the quiz has a published or unpublished draft state.,
     unpublishable (boolean, optional): Whether the assignment's 'published' state can be changed to false. Will be false if there are student submissions for the quiz.,
     locked_for_user (boolean, optional): Whether or not this is locked for the user.,
     lock_info (LockInfo, optional): (Optional) Information for the user about the lock. Present when locked_for_user is true.,
     lock_explanation (string, optional): (Optional) An explanation of why this is locked for the user. Present when locked_for_user is true.,
     speedgrader_url (string, optional): Link to SpeedGrader for this quiz. Will not be present if quiz is unpublished,
     quiz_extensions_url (string, optional): Link to endpoint to send extensions for this quiz.,
     permissions (QuizPermissions, optional): Permissions the user has for the quiz,
     all_dates (array[AssignmentDate], optional): list of due dates for the quiz,
     version_number (integer, optional): Current version number of the quiz,
     question_types (array[string], optional): List of question types in the quiz,
     anonymous_submissions (boolean, optional): Whether survey submissions will be kept anonymous (only applicable to 'graded_survey', 'survey' quiz types)
     }
     QuizPermissions {
     read (boolean, optional): whether the user can view the quiz,
     submit (boolean, optional): whether the user may submit a submission for the quiz,
     create (boolean, optional): whether the user may create a new quiz,
     manage (boolean, optional): whether the user may edit, update, or delete the quiz,
     read_statistics (boolean, optional): whether the user may view quiz statistics for this quiz,
     review_grades (boolean, optional): whether the user may review grades for all quiz submissions for this quiz,
     update (boolean, optional): whether the user may update the quiz
 }


 */
