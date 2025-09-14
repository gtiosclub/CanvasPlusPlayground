//
//  QuizQuestionType.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/14/24.
//

public enum QuizQuestionType: String, Codable, CaseIterable {
    case calculatedQuestion = "calculated_question",
         essayQuestion = "essay_question",
         fileUploadQuestion = "file_upload_question",
         fillInMultipleBlanksQuestion = "fill_in_multiple_blanks_question",
         matchingQuestion = "matching_question",
         multipleAnswersQuestion = "multiple_answers_question",
         multipleChoiceQuestion = "multiple_choice_question",
         multipleDropdownsQuestion = "multiple_dropdowns_question",
         numericalQuestion = "numerical_question",
         shortAnswerQuestion = "short_answer_question",
         textOnlyQuestion = "text_only_question",
         trueFalseQuestion = "true_false_question"
}
