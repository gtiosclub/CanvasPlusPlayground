//
//  Quiz.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/14/24.
//

import Foundation
import SwiftData

typealias Quiz = CanvasSchemaV1.Quiz

extension CanvasSchemaV1 {
    @Model
    class Quiz {
        typealias ID = String
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
            get { hideResultsRaw.flatMap { QuizHideResults(rawValue: $0) } }
            set { hideResultsRaw = newValue?.rawValue }
        }

        var quizType: QuizType {
            get { QuizType(rawValue: quizTypeRaw) ?? .assignment }
            set { quizTypeRaw = newValue.rawValue }
        }

        var scoringPolicy: ScoringPolicy? {
            get { scoringPolicyRaw.flatMap { ScoringPolicy(rawValue: $0) } }
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
