//
//  AgentBudget.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/24/26.
//

import Foundation

/// Limits for one agent run. The runtime stops the run as soon as any of them is used up.
///
/// The defaults are sized for the on-device model: a ~4k token window per call, a few seconds
/// per call, and a handful of steps for anything the student is waiting on.
struct AgentBudget: Codable, Hashable, Sendable {
    /// Node executions, counting each node every time it runs.
    var maxSteps: Int
    /// Wall-clock time spent running. Time while the app was suspended doesn't count.
    var maxDuration: Duration
    /// Estimated tokens across every model call in the run (prompt and output).
    var maxTokens: Int
    /// The model's context window. A single call that wouldn't fit fails before it's sent.
    var contextWindow: Int
    /// Room kept free in the window for the model's answer.
    var outputReserve: Int

    init(
        maxSteps: Int = 8,
        maxDuration: Duration = .seconds(60),
        maxTokens: Int = 12_000,
        contextWindow: Int = 4_096,
        outputReserve: Int = 700
    ) {
        self.maxSteps = maxSteps
        self.maxDuration = maxDuration
        self.maxTokens = maxTokens
        self.contextWindow = contextWindow
        self.outputReserve = outputReserve
    }

    static let onDevice = AgentBudget()

    /// The most prompt tokens one call can use and still leave `outputReserve` for the answer.
    var maxPromptTokens: Int {
        max(contextWindow - outputReserve, 0)
    }
}

/// What a run has used so far. Saved with every checkpoint so a resumed run keeps counting.
struct AgentUsage: Codable, Hashable, Sendable {
    var steps = 0
    var tokens = 0
    var modelCalls = 0
    var elapsed: Duration = .zero
}

enum AgentRunError: Error, Equatable, LocalizedError {
    case stepBudgetExceeded(limit: Int)
    case timeBudgetExceeded(limit: Duration)
    case tokenBudgetExceeded(limit: Int)
    /// A node returned `.next` with an id the graph doesn't have.
    case unknownNode(String)
    case checkpointNotFound(UUID)
    /// The checkpoint belongs to a different graph than the one passed to `resume`.
    case graphMismatch(expected: String, found: String)
    /// The run already finished, failed or was cancelled, so there's nothing to resume.
    case notResumable(AgentRunStatus)

    var errorDescription: String? {
        switch self {
        case .stepBudgetExceeded(let limit):
            "The run used all \(limit) of its steps."
        case .timeBudgetExceeded(let limit):
            "The run hit its \(limit.formatted(.units(allowed: [.seconds]))) time limit."
        case .tokenBudgetExceeded(let limit):
            "The run used its \(limit)-token budget."
        case .unknownNode(let id):
            "No node named \"\(id)\" in this graph."
        case .checkpointNotFound(let id):
            "No saved run with id \(id)."
        case let .graphMismatch(expected, found):
            "The saved run is for \"\(found)\", not \"\(expected)\"."
        case .notResumable(let status):
            "The run is \(status.rawValue) and can't be resumed."
        }
    }

    /// Budget errors end the run but leave whatever the nodes already produced in its state.
    var isBudgetExhaustion: Bool {
        switch self {
        case .stepBudgetExceeded, .timeBudgetExceeded, .tokenBudgetExceeded:
            true
        default:
            false
        }
    }
}

/// Rough token counts for budgeting.
///
/// The estimate is deliberately on the high side (about 3.2 characters per token for English),
/// so a prompt the estimator says fits has room to spare in the real window.
struct TokenEstimator: Sendable {
    var charactersPerToken: Double = 3.2

    func tokens(in text: String) -> Int {
        guard !text.isEmpty else { return 0 }
        return Int((Double(text.utf8.count) / charactersPerToken).rounded(.up))
    }
}
