//
//  ProposeReminderTool.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation
import FoundationModels

/// Proposes a local reminder about an assignment, to-do, calendar event or announcement.
@available(iOS 26.0, macOS 26.0, *)
struct ProposeReminderTool: AgentWriteTool {
    @Generable
    struct Arguments {
        @Guide(description: "The evidence id of the item, exactly as a read tool returned it, like assignment:1234.")
        var evidenceID: String

        @Guide(description: "When to remind the student, in ISO 8601 with a time zone, like 2026-10-21T09:00:00-04:00.")
        var remindAt: String
    }

    static let allowedKinds: Set<EvidenceKind> = [.assignment, .toDo, .calendarEvent, .announcement]

    let name = "proposeReminder"
    let description = "Proposes a reminder notification about an item. The student has to approve it before it's scheduled."

    let log: AgentRunLog
    var now: @Sendable () -> Date = { .now }

    func proposal(for arguments: Arguments) async throws -> ProposedAction {
        let item = try await target(arguments.evidenceID, allowedKinds: Self.allowedKinds)

        guard let date = Self.parseDate(arguments.remindAt) else {
            throw ProposalError.invalidDate(arguments.remindAt)
        }
        guard date > now() else {
            throw ProposalError.dateInPast
        }

        return ProposedAction(kind: .reminder(at: date), target: item)
    }

    /// Accepts ISO 8601 with or without fractional seconds.
    static func parseDate(_ text: String) -> Date? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: trimmed) {
            return date
        }

        formatter.formatOptions.insert(.withFractionalSeconds)
        return formatter.date(from: trimmed)
    }
}
