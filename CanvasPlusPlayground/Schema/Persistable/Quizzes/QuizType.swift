//
//  QuizType.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/14/24.
//

import Foundation

enum QuizType: String, Codable, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    
    case practiceQuiz = "practice_quiz", assignment = "assignment", gradedSurvey = "graded_survey", survey = "survey", quizzesNext = "quizzes.next", unknown = "unknown"
    
    var title: String {
        switch self {
        case .practiceQuiz: "Practice Quizzes"
        case .assignment: "Assignment Quizzes"
        case .gradedSurvey: "Graded Surveys"
        case .survey: "Surveys"
        case .quizzesNext: "New Quizzes"
        case .unknown: "Unknown"
        }
    }
}
