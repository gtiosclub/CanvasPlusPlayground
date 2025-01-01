//
//  QuizSubmissionWorkflowState.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/26/24.
//

public enum QuizSubmissionWorkflowState: String, Codable {
    // swiftlint:disable identifier_name
    case untaken, pending_review, complete, settings_only, preview
    // swiftlint:enable identifier_name
}
