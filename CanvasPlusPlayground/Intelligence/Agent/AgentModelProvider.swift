//
//  AgentModelProvider.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation
import FoundationModels

/// The seam for tier routing. Features ask an `AgentModelRouter` for a provider and call
/// `respond(to:tools:generating:)` without caring which model (if any) answers.
///
/// Outputs are always `@Generable` types. That single Swift definition gives the on-device model
/// its schema directly, and `AgentOutputSchema` turns it into JSON Schema for a cloud provider later.
@available(iOS 26.0, macOS 26.0, *)
protocol AgentModelProvider: Sendable {
    var tier: AgentTier { get }

    /// Whether this provider can answer right now (e.g. Apple Intelligence is on and the model is downloaded).
    var isAvailable: Bool { get }

    func respond<Output: Generable>(
        to prompt: AgentPrompt,
        tools: [any Tool],
        generating type: Output.Type
    ) async throws -> AgentResponse<Output>
}

/// Where an answer comes from. Every feature has to work at `.none`.
enum AgentTier: Int, Comparable, Sendable, CaseIterable {
    /// No model. Pure Swift fallback.
    case none = 0
    /// On-device FoundationModels. The default.
    case onDevice = 1
    /// Cloud model (Gemini), explicit opt-in only, with the student's own key (#604).
    case cloud = 2

    static func < (lhs: AgentTier, rhs: AgentTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct AgentPrompt: Sendable {
    /// System-level guidance: role, rules, citation format.
    var instructions: String
    /// The request for this call.
    var text: String
    /// `nil` uses the model's default. Lower is more deterministic.
    var temperature: Double?
    /// Every course whose content is in `instructions` or `text`. Only the cloud tier uses it:
    /// a request naming a course the student hasn't shared with the cloud isn't sent.
    var courseIDs: Set<String>

    init(instructions: String, text: String, temperature: Double? = nil, courseIDs: Set<String> = []) {
        self.instructions = instructions
        self.text = text
        self.temperature = temperature
        self.courseIDs = courseIDs
    }
}

struct AgentResponse<Output> {
    let content: Output
    /// Which tier produced it.
    let tier: AgentTier
    /// Names of the tools the model called, in order. Useful for the run trace (#575).
    let toolCalls: [String]
}

enum AgentModelError: Error, Equatable {
    /// The provider can't run here, with a user-facing reason.
    case unavailable(String)
    case contextWindowExceeded
    case guardrailViolation
    case refused
    case rateLimited
    /// The model's output didn't fit the requested type.
    case decodingFailed
    /// A scripted provider ran out of steps.
    case scriptExhausted
    /// A script asked for a tool that wasn't passed in.
    case toolNotFound(String)
    case other(String)
}

extension AgentModelError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unavailable(let reason): reason
        case .contextWindowExceeded: "The request was too long for the model."
        case .guardrailViolation: "The model declined because of its safety guidelines."
        case .refused: "The model declined to answer."
        case .rateLimited: "The model is busy right now. Try again in a moment."
        case .decodingFailed: "The model's answer wasn't in the expected format."
        case .scriptExhausted: "The scripted model ran out of steps."
        case .toolNotFound(let name): "The model asked for a tool that isn't available: \(name)."
        case .other(let message): message
        }
    }
}
