//
//  AgentWriteTool.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation
import FoundationModels

/// A tool that asks to change something (reminder, pin, to-do). It never does the change:
/// it queues a `ProposedAction` in the run log and tells the model the student still has to approve.
@available(iOS 26.0, macOS 26.0, *)
protocol AgentWriteTool: Tool where Output == ProposalReceipt {
    var log: AgentRunLog { get }

    /// The action to propose, or a `ProposalError` explaining why it can't be proposed.
    func proposal(for arguments: Arguments) async throws -> ProposedAction
}

enum ProposalError: Error, Hashable {
    /// The id wasn't returned by a read tool in this run, so the agent can't act on it.
    case unknownEvidence(String)
    case unsupportedKind(EvidenceKind)
    case invalidDate(String)
    case dateInPast
}

/// What a write tool tells the model. Rejections are explained so the model can correct itself.
enum ProposalReceipt: Hashable, Sendable {
    case proposed(ProposedAction)
    case rejected(ProposalError)

    var promptText: String {
        switch self {
        case .proposed(let action):
            "Proposed \"\(action.title)\". It only happens if the student approves it; don't say it's done."
        case .rejected(.unknownEvidence(let id)):
            "Not proposed: \(id) isn't a record from this conversation. Look it up with a read tool first and use its id."
        case .rejected(.unsupportedKind(let kind)):
            "Not proposed: this action doesn't apply to a \(kind.rawValue)."
        case .rejected(.invalidDate(let text)):
            "Not proposed: couldn't read the date \"\(text)\". Use ISO 8601, like 2026-10-21T09:00:00-04:00."
        case .rejected(.dateInPast):
            "Not proposed: that time has already passed."
        }
    }
}

@available(iOS 26.0, macOS 26.0, *)
extension ProposalReceipt: PromptRepresentable {
    var promptRepresentation: Prompt {
        promptText
    }
}

@available(iOS 26.0, macOS 26.0, *)
extension AgentWriteTool {
    func call(arguments: Arguments) async throws -> ProposalReceipt {
        do {
            let action = await log.propose(try await proposal(for: arguments))
            return .proposed(action)
        } catch let error as ProposalError {
            return .rejected(error)
        }
    }

    /// The evidence for `id`, as long as a read tool returned it during this run.
    func target(_ id: String, allowedKinds: Set<EvidenceKind>) async throws -> Evidence {
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let evidence = await log.evidence(withID: trimmed) else {
            throw ProposalError.unknownEvidence(trimmed)
        }
        guard allowedKinds.contains(evidence.ref.kind) else {
            throw ProposalError.unsupportedKind(evidence.ref.kind)
        }
        return evidence
    }
}
