//
//  QuizSubmissionWorkflowState.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/26/24.
//


public enum QuizSubmissionWorkflowState: String, Codable {
    case untaken, pending_review, complete, settings_only, preview
}