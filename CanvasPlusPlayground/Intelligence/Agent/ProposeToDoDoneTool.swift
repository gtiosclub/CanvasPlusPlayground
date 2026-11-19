//
//  ProposeToDoDoneTool.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation
import FoundationModels

/// Proposes taking a finished item off the student's Canvas to-do list.
@available(iOS 26.0, macOS 26.0, *)
struct ProposeToDoDoneTool: AgentWriteTool {
    @Generable
    struct Arguments {
        @Guide(description: "The evidence id of the to-do, exactly as listToDos returned it, like todo:1234.")
        var evidenceID: String
    }

    let name = "proposeToDoDone"
    let description = "Proposes marking a to-do as done, which removes it from the Canvas to-do list. The student has to approve it."

    let log: AgentRunLog

    func proposal(for arguments: Arguments) async throws -> ProposedAction {
        ProposedAction(kind: .markToDoDone, target: try await target(arguments.evidenceID, allowedKinds: [.toDo]))
    }
}
