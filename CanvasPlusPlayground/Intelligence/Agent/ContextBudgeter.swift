//
//  ContextBudgeter.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/24/26.
//

import Foundation

/// Picks which evidence goes into a prompt when it can't all fit.
///
/// Candidates are ranked by how well they match the objective (plus a boost for things due or
/// happening soon). Every candidate that fits gets at least a one-line summary; then the
/// highest-ranked ones are upgraded to their full entry (with snippet). The top
/// `guaranteedFullEntries` may push the lowest-ranked summaries out to make room; the rest are
/// only upgraded with tokens left over. So the best matches always come with detail, and
/// lower-ranked items get shorter before they disappear.
struct ContextBudgeter: Sendable {
    var estimator = TokenEstimator()
    var guaranteedFullEntries = 3

    /// How much a title match counts compared with a match in the snippet.
    var titleWeight = 3.0
    var courseWeight = 1.5
    var snippetWeight = 1.0

    func fit(
        _ candidates: [Evidence],
        objective: String,
        tokenBudget: Int,
        now: Date = .now
    ) -> BudgetedContext {
        let ranked = rank(candidates, objective: objective, now: now)

        var entries: [BudgetedContext.Entry] = []
        var used = 0

        // Pass 1: a summary line for as many as fit, best first.
        for item in ranked {
            let cost = estimator.tokens(in: Self.summaryLine(for: item.evidence)) + 1
            guard used + cost <= tokenBudget else { break }
            entries.append(.init(evidence: item.evidence, score: item.score, isFull: false))
            used += cost
        }

        // Pass 2: upgrade to the full entry, best first.
        var index = 0
        while index < entries.count {
            let evidence = entries[index].evidence
            let extra = estimator.tokens(in: evidence.promptText) - estimator.tokens(in: Self.summaryLine(for: evidence))

            // The best few can push out the lowest-ranked summaries to make room.
            if index < guaranteedFullEntries {
                while used + extra > tokenBudget, entries.count - 1 > index, entries.last?.isFull == false {
                    let dropped = entries.removeLast()
                    used -= estimator.tokens(in: Self.summaryLine(for: dropped.evidence)) + 1
                }
            }

            if used + max(extra, 0) <= tokenBudget {
                entries[index].isFull = true
                used += max(extra, 0)
            }
            index += 1
        }

        let omitted = ranked.count - entries.count
        var lines = entries.map { $0.isFull ? $0.evidence.promptText : Self.summaryLine(for: $0.evidence) }
        if omitted > 0 {
            let note = "(\(omitted) more not shown)"
            if used + estimator.tokens(in: note) <= tokenBudget {
                lines.append(note)
            }
        }

        let text = lines.joined(separator: "\n")
        return BudgetedContext(
            text: text,
            entries: entries,
            omittedCount: omitted,
            estimatedTokens: estimator.tokens(in: text)
        )
    }

    /// Candidates sorted by score, highest first. Ties keep their original order.
    func rank(_ candidates: [Evidence], objective: String, now: Date = .now) -> [(evidence: Evidence, score: Double)] {
        let terms = Self.terms(in: objective)

        return candidates.enumerated()
            .map { offset, evidence in
                (offset: offset, evidence: evidence, score: score(evidence, terms: terms, now: now))
            }
            .sorted { $0.score != $1.score ? $0.score > $1.score : $0.offset < $1.offset }
            .map { (evidence: $0.evidence, score: $0.score) }
    }

    func score(_ evidence: Evidence, terms: Set<String>, now: Date) -> Double {
        var score = 0.0

        if !terms.isEmpty {
            let title = Self.terms(in: evidence.title)
            let course = Self.terms(in: evidence.facts.courseName ?? "")
            let snippet = Self.terms(in: evidence.snippet)

            let matched = Double(terms.intersection(title).count) * titleWeight
                + Double(terms.intersection(course).count) * courseWeight
                + Double(terms.intersection(snippet).count) * snippetWeight
            score += matched / Double(terms.count)
        }

        return score + timeBoost(for: evidence.facts, now: now)
    }

    /// Up to +1 for things due or starting in the next week, sooner is higher. Recently
    /// missed work and fresh announcements get a smaller bump.
    private func timeBoost(for facts: EvidenceFacts, now: Date) -> Double {
        let day = 86_400.0

        if let date = facts.dueDate ?? facts.startDate {
            let days = date.timeIntervalSince(now) / day
            if days >= 0 && days <= 7 {
                return 1 - days / 7 * 0.7
            }
            if days < 0 && days >= -3 {
                return 0.4
            }
            return 0
        }

        if let postedAt = facts.postedAt {
            let daysAgo = now.timeIntervalSince(postedAt) / day
            return daysAgo >= 0 && daysAgo <= 3 ? 0.3 : 0
        }

        return 0
    }

    /// The first line of `promptText`: id, title and facts, without the snippet.
    static func summaryLine(for evidence: Evidence) -> String {
        evidence.promptText.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? evidence.promptText
    }

    private static let stopWords: Set<String> = [
        "the", "and", "for", "are", "but", "not", "you", "your", "all", "any", "can", "had", "her",
        "was", "one", "our", "out", "has", "have", "what", "when", "which", "who", "will", "with",
        "this", "that", "from", "they", "been", "there", "their", "about", "into", "than", "then",
        "them", "these", "would", "should", "could", "does", "did", "how", "why", "its", "due"
    ]

    /// Lowercased words longer than two characters, minus common words. Course codes like
    /// "CS 1331" keep their number as its own term.
    static func terms(in text: String) -> Set<String> {
        let words = text.lowercased().split { !$0.isLetter && !$0.isNumber }
        return Set(
            words
                .map(String.init)
                .filter { ($0.count > 2 || $0.allSatisfy(\.isNumber)) && !stopWords.contains($0) }
        )
    }
}

struct BudgetedContext: Sendable {
    struct Entry: Sendable {
        let evidence: Evidence
        let score: Double
        /// `false` when only the one-line summary made it in.
        var isFull: Bool
    }

    /// Ready to drop into a prompt.
    let text: String
    /// What made it in, best first.
    let entries: [Entry]
    /// Candidates that didn't fit even as a summary.
    let omittedCount: Int
    let estimatedTokens: Int

    var fullEvidence: [Evidence] {
        entries.filter(\.isFull).map(\.evidence)
    }

    var summarizedEvidence: [Evidence] {
        entries.filter { !$0.isFull }.map(\.evidence)
    }

    /// Everything the model was shown, in either form. These are the ids it may cite.
    var includedEvidence: [Evidence] {
        entries.map(\.evidence)
    }
}
