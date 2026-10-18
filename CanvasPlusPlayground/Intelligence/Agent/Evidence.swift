//
//  Evidence.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/8/26.
//

import Foundation

/// A record an agent tool found, pointing back at the Canvas data it came from.
///
/// Agent tools return `Evidence`, never free-form strings. Every claim the agent makes
/// has to cite at least one of these, which is what lets the EvidenceGate (#570) check
/// the claim against the real record before it's shown.
struct Evidence: Identifiable, Hashable, Codable, Sendable {
    /// Snippets are capped so a handful of results fits in the on-device model's ~4k context window.
    static let maxSnippetLength = 280

    let ref: EvidenceRef
    let title: String
    /// A short, plain-text excerpt (HTML stripped, whitespace collapsed, at most `maxSnippetLength` characters).
    let snippet: String
    /// Structured values the gate can recheck against the source (dates, points, scores).
    let facts: EvidenceFacts

    /// Stable across calls, e.g. `assignment:1234`. This is what the model cites.
    var id: String { ref.id }

    init(ref: EvidenceRef, title: String, snippet: String?, facts: EvidenceFacts = .init()) {
        self.ref = ref
        self.title = Self.plainText(title)
        self.snippet = Self.boundedSnippet(snippet ?? "")
        self.facts = facts
    }
}

/// The kinds of Canvas records evidence can point to.
enum EvidenceKind: String, Codable, Sendable, CaseIterable {
    case course
    case assignment
    case announcement
    case calendarEvent = "event"
    case toDo = "todo"
    case file
}

/// A typed reference to the record behind a piece of evidence.
///
/// Everything except calendar events is a persisted SwiftData model and can be looked up
/// by `recordID`. Calendar events come from the course ICS feed and aren't persisted, so
/// their `recordID` is the event's `UID` from the feed.
enum EvidenceRef: Hashable, Codable, Sendable {
    case course(id: String)
    case assignment(id: String, courseID: String)
    case announcement(id: String, courseID: String)
    case calendarEvent(uid: String, courseID: String)
    case toDo(id: String, courseID: String?)
    case file(id: String, courseID: String)

    var kind: EvidenceKind {
        switch self {
        case .course:
            .course
        case .assignment:
            .assignment
        case .announcement:
            .announcement
        case .calendarEvent:
            .calendarEvent
        case .toDo:
            .toDo
        case .file:
            .file
        }
    }

    var recordID: String {
        switch self {
        case .course(let id),
             .assignment(let id, _),
             .announcement(let id, _),
             .toDo(let id, _),
             .file(let id, _):
            id
        case .calendarEvent(let uid, _):
            uid
        }
    }

    var courseID: String? {
        switch self {
        case .course(let id):
            id
        case .assignment(_, let courseID),
             .announcement(_, let courseID),
             .calendarEvent(_, let courseID),
             .file(_, let courseID):
            courseID
        case .toDo(_, let courseID):
            courseID
        }
    }

    var id: String { "\(kind.rawValue):\(recordID)" }
}

/// Values from the source record that a claim might depend on.
/// Only set what the record actually has; the gate treats `nil` as "nothing to check".
struct EvidenceFacts: Hashable, Codable, Sendable {
    var courseName: String?
    var dueDate: Date?
    var startDate: Date?
    var endDate: Date?
    var postedAt: Date?
    var pointsPossible: Double?
    var score: Double?
    /// Assignment group weight as a percentage, e.g. 40 for 40%.
    var weight: Double?
    var location: String?
}

// MARK: - Snippets

extension Evidence {
    /// Strips HTML, decodes common entities, collapses whitespace and caps the length,
    /// cutting at a word boundary when one is close to the limit.
    static func boundedSnippet(_ raw: String) -> String {
        let text = plainText(raw)
        guard text.count > maxSnippetLength else { return text }

        let cutoff = text.index(text.startIndex, offsetBy: maxSnippetLength - 1)
        var truncated = String(text[..<cutoff])

        // Prefer a word boundary if it doesn't throw away too much.
        if let lastSpace = truncated.lastIndex(of: " "),
           truncated.distance(from: lastSpace, to: truncated.endIndex) < 40 {
            truncated = String(truncated[..<lastSpace])
        }

        return truncated.trimmingCharacters(in: .whitespaces) + "…"
    }

    static func plainText(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "<(br|p|div|li|h[1-6])[^>]*>", with: " ", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Prompt text

extension Evidence {
    /// One compact entry for the model, e.g.
    /// `[assignment:1234] Problem Set 5 | course: CS 1331 | due: 2026-10-08T20:59:00Z | points: 10`
    /// followed by the snippet on the next line. Dates are ISO 8601 so the model copies them exactly.
    var promptText: String {
        var fields = ["[\(id)] \(title)"]

        if let courseName = facts.courseName { fields.append("course: \(courseName)") }
        if let dueDate = facts.dueDate { fields.append("due: \(Self.iso(dueDate))") }
        if let startDate = facts.startDate { fields.append("starts: \(Self.iso(startDate))") }
        if let endDate = facts.endDate { fields.append("ends: \(Self.iso(endDate))") }
        if let postedAt = facts.postedAt { fields.append("posted: \(Self.iso(postedAt))") }
        if let pointsPossible = facts.pointsPossible { fields.append("points: \(Self.number(pointsPossible))") }
        if let score = facts.score { fields.append("score: \(Self.number(score))") }
        if let weight = facts.weight { fields.append("weight: \(Self.number(weight))%") }
        if let location = facts.location { fields.append("location: \(location)") }

        let header = fields.joined(separator: " | ")
        return snippet.isEmpty ? header : "\(header)\n  \(snippet)"
    }

    private static func iso(_ date: Date) -> String {
        date.formatted(.iso8601)
    }

    private static func number(_ value: Double) -> String {
        abs(value) < 1e15 && value.rounded() == value ? String(Int(value)) : String(value)
    }
}
