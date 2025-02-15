//
//  QuizAPI.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/22/24.
//

import Foundation

// https://github.com/instructure/canvas-ios/blob/master/Core/Core/Quizzes/APIQuiz.swift
// https://canvas.instructure.com/doc/api/quizzes.html
struct QuizAPI: APIResponse, Identifiable {
    typealias Model = Quiz

    let id: Int

    // swiftlint:disable identifier_name
    let access_code: String?
    let all_dates: [APIAssignmentDate]?
    /** Nil when `quiz_type` is `quizzes.next`. */
    let allowed_attempts: Int?
    let assignment_id: ID?
    let cant_go_back: Bool?
    let description: String?
    let due_at: Date?
    /** Nil when `quiz_type` is `quizzes.next`. */
    let has_access_code: Bool?
    let hide_correct_answers_at: Date?
    let hide_results: QuizHideResults?
    let html_url: URL
    // let id: ID
    let ip_filter: String?
    let lock_at: Date?
    let lock_explanation: String?
    /** Nil when `quiz_type` is `quizzes.next`. */
    let locked_for_user: Bool?
    let mobile_url: URL
    /** Nil when `quiz_type` is `quizzes.next`. */
    let one_question_at_a_time: Bool?
    let points_possible: Double?
    let published: Bool?
    /** Nil when `quiz_type` is `quizzes.next`. */
    let question_count: Int?
    let question_types: [QuizQuestionType]?
    let quiz_type: QuizType
    let require_lockdown_browser_for_results: Bool
    let require_lockdown_browser: Bool
    let scoring_policy: ScoringPolicy?
    let show_correct_answers: Bool?
    let show_correct_answers_at: Date?
    let show_correct_answers_last_attempt: Bool?
    /** Nil when `quiz_type` is `quizzes.next`. */
    let shuffle_answers: Bool?
    let time_limit: Double? // minutes
    let title: String
    let unlock_at: Date?
    let unpublishable: Bool?
    let anonymous_submissions: Bool?
    // let assignment_group_id: String?
    // let lock_info: LockInfoModel?
    // let one_time_results: Bool
    // let permissions: APIQuizPermissions?
    // let preview_url: URL
    // let quiz_extensions_url: URL?
    // let speedgrader_url: URL?
    // let version_number: Int
    // swiftlint:enable identifier_name

    func createModel() -> Quiz {
        Quiz(api: self)
    }
}
