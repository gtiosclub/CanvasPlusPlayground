//
//  AgentRunLog.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation

/// Everything one agent run produced: the evidence its read tools returned (what the
/// EvidenceGate checks citations against) and the actions its write tools proposed.
actor AgentRunLog {
    private var evidenceByID: [String: Evidence] = [:]
    private var evidenceOrder: [String] = []
    private(set) var proposedActions: [ProposedAction] = []

    /// Evidence in the order it was first returned.
    var evidence: [Evidence] {
        evidenceOrder.compactMap { evidenceByID[$0] }
    }

    func record(_ items: [Evidence]) {
        for item in items {
            if evidenceByID[item.id] == nil {
                evidenceOrder.append(item.id)
            }
            evidenceByID[item.id] = item
        }
    }

    /// Evidence with this id, but only if a read tool returned it during this run.
    func evidence(withID id: String) -> Evidence? {
        evidenceByID[id]
    }

    /// Adds the proposal unless an identical one is already queued. Returns the queued action.
    @discardableResult
    func propose(_ action: ProposedAction) -> ProposedAction {
        if let existing = proposedActions.first(where: { $0.isDuplicate(of: action) }) {
            return existing
        }

        proposedActions.append(action)
        return action
    }
}
