//
//  ProposedAction.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation

/// Something the agent wants to do on the student's behalf. Write tools only create these;
/// nothing happens until the student approves it in `ProposedActionsView`.
struct ProposedAction: Identifiable, Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        /// A local notification. Never changes anything on Canvas.
        case reminder(at: Date)
        /// Pin the item in Canvas Plus. Local only.
        case pin
        /// Remove a to-do from the Canvas to-do list (the same as "Ignore Item" in the to-do list).
        case markToDoDone
    }

    let id: UUID
    let kind: Kind
    /// The record the action is about. Always evidence a tool returned during the same run.
    let target: Evidence

    init(id: UUID = UUID(), kind: Kind, target: Evidence) {
        self.id = id
        self.kind = kind
        self.target = target
    }

    /// Short title for the approval card, e.g. "Remind me about Problem Set 5".
    var title: String {
        switch kind {
        case .reminder:
            "Remind me about \(target.title)"
        case .pin:
            "Pin \(target.title)"
        case .markToDoDone:
            "Mark \(target.title) as done"
        }
    }

    /// What will happen if the student approves, in plain words.
    var detail: String {
        switch kind {
        case .reminder(let date):
            "Sends a notification on \(date.formatted(date: .abbreviated, time: .shortened)). Nothing changes on Canvas."
        case .pin:
            "Adds it to your pinned items in Canvas Plus."
        case .markToDoDone:
            "Removes it from your Canvas to-do list."
        }
    }

    var systemImage: String {
        switch kind {
        case .reminder:
            "bell.badge"
        case .pin:
            "pin"
        case .markToDoDone:
            "checkmark.circle"
        }
    }

    /// Two proposals that would do the same thing.
    func isDuplicate(of other: ProposedAction) -> Bool {
        kind == other.kind && target.id == other.target.id
    }
}
