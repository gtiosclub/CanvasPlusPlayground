//
//  EvidenceGate.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation

/// Deterministic post-filter between the model and the UI.
///
/// For every claim:
/// 1. Each citation has to be evidence a tool actually returned during this run, and the record
///    behind it has to still exist (re-read through an `EvidenceResolver`). Citations that fail
///    either test are ignored. A claim with no citation left is dropped and never rendered.
/// 2. Every date, points, score or weight the claim asserts is rechecked in Swift against the
///    re-read records. A match passes. A mismatch becomes a conflict carrying the source value,
///    so the UI can show a conflict card (or drop it). A value none of the cited records has is
///    unsupported, and the claim is dropped.
///
/// No model is involved, so the same claims and records always give the same result.
struct EvidenceGate: Sendable {
    /// Numbers within this distance count as equal (points, scores, weights).
    static let numericTolerance = 0.01

    private let known: [String: Evidence]
    private let resolver: any EvidenceResolver
    private let calendar: Calendar

    /// - Parameters:
    ///   - evidence: everything the tools returned during this run. Citations to anything else are ignored.
    ///   - resolver: re-reads records so checks run against current data, not what the tool saw earlier.
    init(evidence: [Evidence], resolver: any EvidenceResolver, calendar: Calendar = .current) {
        self.known = Dictionary(evidence.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.resolver = resolver
        self.calendar = calendar
    }

    func evaluate(_ claims: [AgentClaim]) async -> EvidenceGateResult {
        var result = EvidenceGateResult()

        for claim in claims {
            switch await verdict(for: claim) {
            case .verified(let evidence):
                result.verified.append(VerifiedClaim(claim: claim, evidence: evidence))
            case let .conflict(mismatches, evidence):
                result.conflicts.append(ConflictedClaim(claim: claim, mismatches: mismatches, evidence: evidence))
            case .dropped(let reason):
                result.dropped.append(DroppedClaim(claim: claim, reason: reason))
            }
        }

        return result
    }

    // MARK: - Private

    private enum Verdict {
        case verified([Evidence])
        case conflict([ClaimMismatch], [Evidence])
        case dropped(DroppedClaim.Reason)
    }

    private func verdict(for claim: AgentClaim) async -> Verdict {
        guard !claim.citations.isEmpty else {
            return .dropped(.noCitations)
        }

        // Resolve each citation once, in the order the model gave them.
        var resolved: [Evidence] = []
        var seen = Set<String>()
        for citation in claim.citations where seen.insert(citation).inserted {
            guard let ref = known[citation]?.ref,
                  let current = await resolver.resolve(ref) else {
                continue
            }
            resolved.append(current)
        }

        guard !resolved.isEmpty else {
            return .dropped(.unresolvableCitations(claim.citations))
        }

        var mismatches: [ClaimMismatch] = []
        for check in claim.checks {
            switch outcome(of: check, against: resolved) {
            case .match:
                continue
            case .mismatch(let mismatch):
                mismatches.append(mismatch)
            case .unsupported:
                return .dropped(.unsupportedCheck(check))
            }
        }

        return mismatches.isEmpty ? .verified(resolved) : .conflict(mismatches, resolved)
    }

    private enum CheckOutcome {
        case match
        case mismatch(ClaimMismatch)
        case unsupported
    }

    /// A check passes if any cited record matches. It's a mismatch if at least one cited record
    /// has the value but none match, and unsupported if no cited record has the value at all.
    private func outcome(of check: ClaimCheck, against evidence: [Evidence]) -> CheckOutcome {
        var firstMismatch: ClaimMismatch?

        for item in evidence {
            guard let (sourceValue, matches) = compare(check, with: item.facts) else { continue }

            if matches {
                return .match
            } else if firstMismatch == nil {
                firstMismatch = ClaimMismatch(check: check, sourceValue: sourceValue, evidenceID: item.id)
            }
        }

        if let firstMismatch {
            return .mismatch(firstMismatch)
        }

        return .unsupported
    }

    /// The record's value for `check` and whether the claim matches it, or `nil` if the record
    /// doesn't have that value.
    private func compare(_ check: ClaimCheck, with facts: EvidenceFacts) -> (ClaimMismatch.Value, Bool)? {
        switch check {
        case let .date(field, claimed, precision):
            field.value(in: facts).map { (.date($0), datesMatch(claimed, $0, precision: precision)) }
        case .pointsPossible(let claimed):
            facts.pointsPossible.map { (.number($0), numbersMatch(claimed, $0)) }
        case .score(let claimed):
            facts.score.map { (.number($0), numbersMatch(claimed, $0)) }
        case .weight(let claimed):
            facts.weight.map { (.number($0), numbersMatch(claimed, $0)) }
        }
    }

    private func numbersMatch(_ claimed: Double, _ source: Double) -> Bool {
        abs(claimed - source) <= Self.numericTolerance
    }

    private func datesMatch(_ claimed: Date, _ source: Date, precision: ClaimCheck.DatePrecision) -> Bool {
        switch precision {
        case .minute:
            calendar.isDate(claimed, equalTo: source, toGranularity: .minute)
        case .day:
            calendar.isDate(claimed, inSameDayAs: source)
        }
    }
}

/// What the gate decided for a batch of claims, in the order the claims came in.
struct EvidenceGateResult: Sendable {
    /// Safe to render as-is.
    var verified: [VerifiedClaim] = []
    /// Cited real records but got a value wrong. Render as a conflict card or drop.
    var conflicts: [ConflictedClaim] = []
    /// Never render these.
    var dropped: [DroppedClaim] = []
}

struct VerifiedClaim: Sendable {
    let claim: AgentClaim
    /// The re-read records the claim cites, for provenance chips.
    let evidence: [Evidence]
}

struct ConflictedClaim: Sendable {
    let claim: AgentClaim
    let mismatches: [ClaimMismatch]
    let evidence: [Evidence]
}

/// A claimed value that doesn't match the record, with what the record actually says.
struct ClaimMismatch: Hashable, Sendable {
    enum Value: Hashable, Sendable {
        case date(Date)
        case number(Double)
    }

    let check: ClaimCheck
    let sourceValue: Value
    let evidenceID: String
}

struct DroppedClaim: Sendable {
    enum Reason: Hashable, Sendable {
        /// The claim didn't cite anything.
        case noCitations
        /// None of the citations was evidence from this run whose record still exists.
        case unresolvableCitations([String])
        /// The claim asserts a value that none of its cited records has.
        case unsupportedCheck(ClaimCheck)
    }

    let claim: AgentClaim
    let reason: Reason
}
