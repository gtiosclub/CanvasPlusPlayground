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
        case .practiceQuiz: return "Practice Quizzes"
        case .assignment: return "Assignment Quizzes"
        case .gradedSurvey: return "Graded Surveys"
        case .survey: return "Surveys"
        case .quizzesNext: return "New Quizzes"
        case .unknown: return "Unknown"
        }
    }
}
