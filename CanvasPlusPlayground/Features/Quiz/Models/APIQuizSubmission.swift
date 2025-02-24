//
//  APIQuizSubmission.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/26/24.
//
import Foundation

// swiftlint:disable commented_code identifier_name
struct APIQuizSubmission: Codable {
    let attempt: Int?
    let attempts_left: Int
    let end_at: Date?
    let extra_time: Double?
    let finished_at: Date?
    let id: Int
    let quiz_id: Int
    let score: Double?
    let started_at: Date?
    let submission_id: Int
    let user_id: Int
    let validation_token: String?
    let workflow_state: QuizSubmissionWorkflowState
    // let extra_attempts: Int?
    // let fudge_points: Int?
    // let has_seen_results: Bool
    // let kept_score: Double?
    // let manually_unlocked: Bool
    // let overdue_and_needs_submission: Bool
    // let score_before_regrade: Double?
    // let time_spent: TimeInterval?
}
