//
//  QuizSubmissionWorkflowState.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/26/24.
//

// swiftlint:disable identifier_name
public enum QuizSubmissionWorkflowState: String, Codable {
    case untaken
    case pending_review
    case complete
    case settings_only
    case preview
}
