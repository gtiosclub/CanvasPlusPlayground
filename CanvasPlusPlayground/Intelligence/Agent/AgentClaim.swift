//
//  AgentClaim.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation

/// One statement the agent wants to show the student, plus the evidence it cites and any
/// specific values it asserts. The EvidenceGate decides whether it gets shown.
///
/// This is the gate's input type. The model-facing output schema (#572) maps onto it.
struct AgentClaim: Identifiable, Hashable, Codable, Sendable {
    var id = UUID()
    /// The sentence shown to the student, e.g. "Problem Set 5 is due Thursday at 11:59 PM."
    var text: String
    /// Evidence ids the claim relies on, e.g. `["assignment:1234"]`.
    var citations: [String]
    /// Values in `text` that have to match the cited records exactly.
    var checks: [ClaimCheck] = []
}

/// A value a claim asserts that the gate can recheck against the source record.
enum ClaimCheck: Hashable, Codable, Sendable {
    case date(ClaimDateField, Date, precision: DatePrecision = .minute)
    case pointsPossible(Double)
    case score(Double)
    case weight(Double)

    enum DatePrecision: String, Hashable, Codable, Sendable {
        /// Same minute. For claims like "due at 11:59 PM".
        case minute
        /// Same calendar day. For claims like "due Friday".
        case day
    }
}

/// Which date on the record a date check refers to.
enum ClaimDateField: String, Hashable, Codable, Sendable, CaseIterable {
    case due
    case start
    case end
    case posted

    func value(in facts: EvidenceFacts) -> Date? {
        switch self {
        case .due:
            facts.dueDate
        case .start:
            facts.startDate
        case .end:
            facts.endDate
        case .posted:
            facts.postedAt
        }
    }
}
