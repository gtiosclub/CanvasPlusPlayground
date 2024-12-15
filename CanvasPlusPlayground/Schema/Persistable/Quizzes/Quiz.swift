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
    var parentId: String
    
    var title: String?
    var htmlUrl: String?
    var mobileUrl: String?
    var previewUrl: String?
    var quizDescription: String? // known as 'description'
    var quizTypeRaw: String
    var assignmentGroupId: Int?
    var timeLimit: Double?
    var shuffleAnswers: Bool?
    var hideResultsRaw: String?
    var showCorrectAnswers: Bool?
    var showCorrectAnswersLastAttempt: Bool?
    var showCorrectAnswersAt: Date?
    var hideCorrectAnswersAt: Date?
    var oneTimeResults: Bool?
    var scoringPolicyRaw: String?
    var allowedAttempts: Int?
    var oneQuestionAtATime: Bool?
    var questionCount: Double?
    var pointsPossible: Double?
    var cantGoBack: Bool?
    var accessCode: String?
    var ipFilter: String?
    var dueAtRaw: Date?
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
    var allDates: [AssignmentDate]
    var versionNumber: Int?
    var questionTypes: [QuizQuestionType]
    var anonymousSubmissions: Bool?
    
    var quizType: QuizType {
        get { QuizType(rawValue: quizTypeRaw) ?? .assignment }
        set { quizTypeRaw = newValue.rawValue }
    }
    
    var hideResults: QuizHideResults? {
        get { return hideResultsRaw.flatMap { QuizHideResults(rawValue: $0) } }
        set { hideResultsRaw = newValue?.rawValue }
    }
    
    var scoringPolicy: ScoringPolicy? {
        get { return scoringPolicyRaw.flatMap { ScoringPolicy(rawValue: $0) } }
        set { scoringPolicyRaw = newValue?.rawValue }
    }
    
    var dueAt: Date { dueAtRaw ?? .distantFuture }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let id = try container.decode(ServerID.self, forKey: .id)
        self.id =  String(describing: id)
        self.parentId = try container.decodeIfPresent(String.self, forKey: .parentId) ?? ""
        
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.htmlUrl = try container.decodeIfPresent(String.self, forKey: .htmlUrl)
        self.mobileUrl = try container.decodeIfPresent(String.self, forKey: .mobileUrl)
        self.previewUrl = try container.decodeIfPresent(String.self, forKey: .previewUrl)
        self.quizDescription = try container.decodeIfPresent(String.self, forKey: .quizDescription)
        self.quizTypeRaw = try container.decodeIfPresent(String.self, forKey: .quizTypeRaw) ?? QuizType.unknown.rawValue
        self.assignmentGroupId = try container.decodeIfPresent(Int.self, forKey: .assignmentGroupId)
        self.timeLimit = try container.decodeIfPresent(Double.self, forKey: .timeLimit)
        self.shuffleAnswers = try container.decodeIfPresent(Bool.self, forKey: .shuffleAnswers)
        self.hideResultsRaw = try container.decodeIfPresent(String.self, forKey: .hideResultsRaw)
        self.showCorrectAnswers = try container.decodeIfPresent(Bool.self, forKey: .showCorrectAnswers)
        self.showCorrectAnswersLastAttempt = try container.decodeIfPresent(Bool.self, forKey: .showCorrectAnswersLastAttempt)
        self.showCorrectAnswersAt = try container.decodeIfPresent(Date.self, forKey: .showCorrectAnswersAt)
        self.hideCorrectAnswersAt = try container.decodeIfPresent(Date.self, forKey: .hideCorrectAnswersAt)
        self.oneTimeResults = try container.decodeIfPresent(Bool.self, forKey: .oneTimeResults)
        self.scoringPolicyRaw = try container.decodeIfPresent(String.self, forKey: .scoringPolicyRaw)
        self.allowedAttempts = try container.decodeIfPresent(Int.self, forKey: .allowedAttempts) ?? 0
        self.oneQuestionAtATime = try container.decodeIfPresent(Bool.self, forKey: .oneQuestionAtATime)
        self.questionCount = try container.decodeIfPresent(Double.self, forKey: .questionCount)
        self.pointsPossible = try container.decodeIfPresent(Double.self, forKey: .pointsPossible)
        self.cantGoBack = try container.decodeIfPresent(Bool.self, forKey: .cantGoBack)
        self.accessCode = try container.decodeIfPresent(String.self, forKey: .accessCode)
        self.ipFilter = try container.decodeIfPresent(String.self, forKey: .ipFilter)
        self.dueAtRaw = try container.decodeIfPresent(Date.self, forKey: .dueAt)
        self.lockAt = try container.decodeIfPresent(Date.self, forKey: .lockAt)
        self.unlockAt = try container.decodeIfPresent(Date.self, forKey: .unlockAt)
        self.published = try container.decodeIfPresent(Bool.self, forKey: .published)
        self.unpublishable = try container.decodeIfPresent(Bool.self, forKey: .unpublishable)
        self.lockedForUser = try container.decodeIfPresent(Bool.self, forKey: .lockedForUser)
        self.lockInfo = try container.decodeIfPresent(LockInfo.self, forKey: .lockInfo)
        self.lockExplanaation = try container.decodeIfPresent(String.self, forKey: .lockExplanaation)
        self.speedGraderURL = try container.decodeIfPresent(String.self, forKey: .speedGraderURL)
        self.quizExtensionsURL = try container.decodeIfPresent(String.self, forKey: .quizExtensionsURL)
        self.permissions = try container.decodeIfPresent(QuizPermissions.self, forKey: .permissions)
        self.allDates = try container.decodeIfPresent([AssignmentDate].self, forKey: .allDates) ?? []
        self.versionNumber = try container.decodeIfPresent(Int.self, forKey: .versionNumber)
        self.questionTypes = try container.decodeIfPresent([QuizQuestionType].self, forKey: .questionTypes) ?? []
        self.anonymousSubmissions = try container.decodeIfPresent(Bool.self, forKey: .anonymousSubmissions)
    }
}

// MARK: Cacheable

extension Quiz: Cacheable {
    typealias ServerID = Int
        
    enum CodingKeys: String, CodingKey {
        case id
        case parentId = "parent_id"
                
        case title
        case htmlUrl = "html_url"
        case mobileUrl = "mobile_url"
        case previewUrl = "preview_url"
        case quizDescription = "description" // known as 'description'
        case quizTypeRaw = "quiz_type"
        case assignmentGroupId = "assignment_group_id"
        case timeLimit = "time_limit"
        case shuffleAnswers = "shuffle_answers"
        case hideResultsRaw = "hide_results"
        case showCorrectAnswers = "show_correct_answers"
        case showCorrectAnswersLastAttempt = "show_correct_answers_last_attempt"
        case showCorrectAnswersAt = "show_correct_answers_at"
        case hideCorrectAnswersAt = "hide_correct_answers_at"
        case oneTimeResults = "one_time_results"
        case scoringPolicyRaw = "scoring_policy"
        case allowedAttempts = "allowed_attempts"
        case oneQuestionAtATime = "one_question_at_a_time"
        case questionCount = "question_count"
        case pointsPossible = "points_possible"
        case cantGoBack = "cant_go_back"
        case accessCode = "access_code"
        case ipFilter = "ip_filter"
        case dueAt = "due_at"
        case lockAt = "lock_at"
        case unlockAt = "unlock_at"
        case published
        case unpublishable
        case lockedForUser = "locked_for_user"
        case lockInfo = "lock_info"
        case lockExplanaation = "lock_explanation"
        case speedGraderURL = "speedgrader_url"
        case quizExtensionsURL = "quiz_extensions_url"
        case permissions = "permissions"
        case allDates = "all_dates"
        case versionNumber = "version_number"
        case questionTypes = "question_types"
        case anonymousSubmissions = "anonymous_submissions"
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(htmlUrl, forKey: .htmlUrl)
        try container.encodeIfPresent(mobileUrl, forKey: .mobileUrl)
        try container.encodeIfPresent(previewUrl, forKey: .previewUrl)
        try container.encodeIfPresent(quizDescription, forKey: .quizDescription)
        try container.encode(quizTypeRaw, forKey: .quizTypeRaw)
        try container.encodeIfPresent(assignmentGroupId, forKey: .assignmentGroupId)
        try container.encodeIfPresent(timeLimit, forKey: .timeLimit)
        try container.encodeIfPresent(shuffleAnswers, forKey: .shuffleAnswers)
        try container.encodeIfPresent(hideResultsRaw, forKey: .hideResultsRaw)
        try container.encode(showCorrectAnswers, forKey: .showCorrectAnswers)
        try container.encode(showCorrectAnswersLastAttempt, forKey: .showCorrectAnswersLastAttempt)
        try container.encodeIfPresent(showCorrectAnswersAt, forKey: .showCorrectAnswersAt)
        try container.encodeIfPresent(hideCorrectAnswersAt, forKey: .hideCorrectAnswersAt)
        try container.encodeIfPresent(oneTimeResults, forKey: .oneTimeResults)
        try container.encodeIfPresent(scoringPolicyRaw, forKey: .scoringPolicyRaw)
        try container.encode(allowedAttempts, forKey: .allowedAttempts)
        try container.encodeIfPresent(oneQuestionAtATime, forKey: .oneQuestionAtATime)
        try container.encodeIfPresent(questionCount, forKey: .questionCount)
        try container.encodeIfPresent(pointsPossible, forKey: .pointsPossible)
        try container.encode(cantGoBack, forKey: .cantGoBack)
        try container.encodeIfPresent(accessCode, forKey: .accessCode)
        try container.encodeIfPresent(ipFilter, forKey: .ipFilter)
        try container.encodeIfPresent(dueAtRaw, forKey: .dueAt)
        try container.encodeIfPresent(lockAt, forKey: .lockAt)
        try container.encodeIfPresent(unlockAt, forKey: .unlockAt)
        try container.encodeIfPresent(published, forKey: .published)
        try container.encodeIfPresent(unpublishable, forKey: .unpublishable)
        try container.encodeIfPresent(lockedForUser, forKey: .lockedForUser)
        try container.encodeIfPresent(lockInfo, forKey: .lockInfo)
        try container.encodeIfPresent(lockExplanaation, forKey: .lockExplanaation)
        try container.encodeIfPresent(speedGraderURL, forKey: .speedGraderURL)
        try container.encodeIfPresent(quizExtensionsURL, forKey: .quizExtensionsURL)
        try container.encodeIfPresent(permissions, forKey: .permissions)
        try container.encodeIfPresent(allDates, forKey: .allDates)
        try container.encodeIfPresent(versionNumber, forKey: .versionNumber)
        try container.encode(questionTypes, forKey: .questionTypes)
        try container.encode(anonymousSubmissions, forKey: .anonymousSubmissions)
    }
    
    func merge(with other: Quiz) {
        self.title = other.title
        self.htmlUrl = other.htmlUrl
        self.mobileUrl = other.mobileUrl
        self.previewUrl = other.previewUrl
        self.quizDescription = other.quizDescription
        self.quizTypeRaw = other.quizTypeRaw
        self.assignmentGroupId = other.assignmentGroupId
        self.timeLimit = other.timeLimit
        self.shuffleAnswers = other.shuffleAnswers
        self.hideResultsRaw = other.hideResultsRaw
        self.showCorrectAnswers = other.showCorrectAnswers
        self.showCorrectAnswersLastAttempt = other.showCorrectAnswersLastAttempt
        self.showCorrectAnswersAt = other.showCorrectAnswersAt
        self.hideCorrectAnswersAt = other.hideCorrectAnswersAt
        self.oneTimeResults = other.oneTimeResults
        self.scoringPolicyRaw = other.scoringPolicyRaw
        self.allowedAttempts = other.allowedAttempts
        self.oneQuestionAtATime = other.oneQuestionAtATime
        self.questionCount = other.questionCount
        self.pointsPossible = other.pointsPossible
        self.cantGoBack = other.cantGoBack
        self.accessCode = other.accessCode
        self.ipFilter = other.ipFilter
        self.dueAtRaw = other.dueAtRaw
        self.lockAt = other.lockAt
        self.unlockAt = other.unlockAt
        self.published = other.published
        self.unpublishable = other.unpublishable
        self.lockedForUser = other.lockedForUser
        self.lockInfo = other.lockInfo
        self.lockExplanaation = other.lockExplanaation
        self.speedGraderURL = other.speedGraderURL
        self.quizExtensionsURL = other.quizExtensionsURL
        self.permissions = other.permissions
        self.allDates = other.allDates
        self.versionNumber = other.versionNumber
        self.questionTypes = other.questionTypes
        self.anonymousSubmissions = other.anonymousSubmissions    }
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
