//
//  QuizType.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/14/24.
//

import Foundation

enum QuizType: String, Codable {
    case practiceQuiz = "practice_quiz", assignment = "assignment", gradedSurvey = "graded_survey", survey = "survey", quizzesNext = "quizzes.next", unknown = "unknown"
}
