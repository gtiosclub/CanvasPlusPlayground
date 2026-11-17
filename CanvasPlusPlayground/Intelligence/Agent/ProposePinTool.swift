//
//  ProposePinTool.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation
import FoundationModels

/// Proposes pinning an assignment, announcement, file or calendar event in Canvas Plus.
@available(iOS 26.0, macOS 26.0, *)
struct ProposePinTool: AgentWriteTool {
    @Generable
    struct Arguments {
        @Guide(description: "The evidence id of the item, exactly as a read tool returned it, like file:5678.")
        var evidenceID: String
    }

    /// The kinds `PinnedItem` supports.
    static let allowedKinds: Set<EvidenceKind> = [.assignment, .announcement, .file, .calendarEvent]

    let name = "proposePin"
    let description = "Proposes pinning an item so it's easy to find. The student has to approve it."

    let log: AgentRunLog

    func proposal(for arguments: Arguments) async throws -> ProposedAction {
        ProposedAction(kind: .pin, target: try await target(arguments.evidenceID, allowedKinds: Self.allowedKinds))
    }
}
