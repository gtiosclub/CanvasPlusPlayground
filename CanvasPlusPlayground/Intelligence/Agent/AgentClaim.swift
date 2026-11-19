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

/// A value a claim asserts about one specific cited record, which the gate rechecks against
/// that record only.
///
/// Tying each check to a record matters for comparisons: a claim citing two assignments and
/// saying "Problem Set 5 is due Oct 8" must match Problem Set 5's date, not whichever cited
/// record happens to be due Oct 8.
struct ClaimCheck: Hashable, Codable, Sendable {
    /// The evidence id the value is about, e.g. `assignment:1234`. Must be one of the claim's citations.
    var evidenceID: String
    var assertion: Assertion

    enum Assertion: Hashable, Codable, Sendable {
        case date(ClaimDateField, Date, precision: DatePrecision)
        case pointsPossible(Double)
        case score(Double)
        case weight(Double)
    }

    enum DatePrecision: String, Hashable, Codable, Sendable {
        /// Same minute. For claims like "due at 11:59 PM".
        case minute
        /// Same calendar day. For claims like "due Friday".
        case day
    }

    init(evidenceID: String, assertion: Assertion) {
        self.evidenceID = evidenceID
        self.assertion = assertion
    }

    static func date(
        _ field: ClaimDateField,
        _ date: Date,
        precision: DatePrecision = .minute,
        of evidenceID: String
    ) -> ClaimCheck {
        ClaimCheck(evidenceID: evidenceID, assertion: .date(field, date, precision: precision))
    }

    static func pointsPossible(_ value: Double, of evidenceID: String) -> ClaimCheck {
        ClaimCheck(evidenceID: evidenceID, assertion: .pointsPossible(value))
    }

    static func score(_ value: Double, of evidenceID: String) -> ClaimCheck {
        ClaimCheck(evidenceID: evidenceID, assertion: .score(value))
    }

    static func weight(_ value: Double, of evidenceID: String) -> ClaimCheck {
        ClaimCheck(evidenceID: evidenceID, assertion: .weight(value))
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
