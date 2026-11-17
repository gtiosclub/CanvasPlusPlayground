//
//  AgentTool.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/8/26.
//

import Foundation
import FoundationModels

/// A `FoundationModels.Tool` that can only return `Evidence`.
///
/// Conformers implement `evidence(for:)`. The `Output == EvidenceBundle` constraint means a
/// tool can't hand the model a free-form string, so everything the model sees from a tool
/// has an id it can cite and the EvidenceGate can check.
@available(iOS 26.0, macOS 26.0, *)
protocol AgentTool: Tool where Output == EvidenceBundle {
    /// The records matching `arguments`, most relevant first.
    func evidence(for arguments: Arguments) async throws -> [Evidence]
}

/// What an `AgentTool` hands back to the model: a list of evidence rendered as compact,
/// citable entries.
struct EvidenceBundle: Hashable, Sendable {
    let evidence: [Evidence]

    var promptText: String {
        guard !evidence.isEmpty else {
            return "No matching records."
        }

        return evidence.map(\.promptText).joined(separator: "\n")
    }
}

@available(iOS 26.0, macOS 26.0, *)
extension AgentTool {
    func call(arguments: Arguments) async throws -> EvidenceBundle {
        EvidenceBundle(evidence: try await evidence(for: arguments))
    }
}

@available(iOS 26.0, macOS 26.0, *)
extension EvidenceBundle: PromptRepresentable {
    var promptRepresentation: Prompt {
        promptText
    }
}
