//
//  Quiz.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/14/24.
//

import Foundation
import SwiftData


@Model
class Quiz: Cacheable {
    typealias ServerID = Int
    
    @Attribute(.unique) var id: String
    var parentId: String
    
    var title: String
    var htmlUrl: String?
    var mobileUrl: String?
    var previewUrl: String?
    var quizDescription: String? // known as 'description'
    var quizTypeRaw: String
    var assignmentGroupId: Int?
    var timeLimit: Int?
    var shuffleAnswers: Bool?
    var hideResultsRaw: String?
    var showCorrectAnswers: Bool
    var showCorrectAnswersLastAttempt: String
    var showCorrectAnswersAt: Date?
    var hideCorrectAnswersAt: Date?
    var oneTimeResults: Bool?
    var scoringPolicyRaw: String?
    var allowedAttempts: Int
    var oneQuestionAtATime: Bool?
    var questionCount: Int?
    var pointsPossible: Int?
    var cantGoBack: Bool
    var accessCode: String?
    var ipFilter: String?
    var dueAt: Date?
    var lockAt: Date?
    var unlockAt: Date?
    var published: Bool?
    var unpublishable: Bool?
    var lockedForUser: Bool?
    var lockInfo: LockInfo?
    var lockExplanaation: String?
    var speedGraderURL: String?
    var quizExtensionsURL: String?
    var permissions: QuizPermissions?
    var allDates: Set<AssignmentDate>
    var versionNumber: Int?
    var questionTypesRaw: [String]
    var anonymousSubmissions: Bool
    
    var quizType: QuizType {
        get { QuizType(rawValue: quizTypeRaw) ?? .assignment }
        set { quizTypeRaw = newValue.rawValue }
    }
    
    var hideResults: QuizHideResults? {
        get { return hideResultsRaw.flatMap { QuizHideResults(rawValue: $0) } }
        set { hideResultsRaw = newValue?.rawValue }
    }
    
    public var questionTypes: [QuizQuestionType] {
        get { return questionTypesRaw.compactMap { QuizQuestionType(rawValue: $0) } }
        set { questionTypesRaw = newValue.map { $0.rawValue } }
    }
    
    public var scoringPolicy: ScoringPolicy? {
        get { return scoringPolicyRaw.flatMap { ScoringPolicy(rawValue: $0) } }
        set { scoringPolicyRaw = newValue?.rawValue }
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
