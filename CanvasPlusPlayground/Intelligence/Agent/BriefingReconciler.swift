//
//  BriefingReconciler.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/24/26.
//

import Foundation

/// An announcement gives a different date than the Canvas record it talks about.
/// Both sides are kept; Canvas is never changed.
struct BriefingConflict: Identifiable, Hashable, Codable, Sendable {
    let claim: BriefingDateClaim
    let record: Evidence
    let recordDate: Date

    var id: String { "\(claim.source.id)|\(record.id)|\(claim.date.timeIntervalSince1970)" }
}

/// A claim that matched a record and agrees with it.
struct BriefingConfirmation: Hashable, Codable, Sendable {
    let claim: BriefingDateClaim
    let record: Evidence
}

struct BriefingReport: Hashable, Codable, Sendable {
    var conflicts: [BriefingConflict] = []
    var confirmations: [BriefingConfirmation] = []
    /// Dates that didn't clearly match one record (a review session, office hours, or two
    /// assignments that fit equally well). Never shown as conflicts.
    var unmatched: [BriefingDateClaim] = []
    var generatedAt = Date.now
}

/// Compares the dates announcements give with the dates on assignments and events. Pure Swift.
///
/// A claim is matched to a record in the same course by title: the share of the record's title
/// words the claim mentions, and any number in the title ("Lab 2", "Quiz 1") has to appear in the
/// claim too. If no record scores high enough, or two tie, the claim stays unmatched rather than
/// guessing. Claims with a time are compared to the minute; day-only claims by day.
struct BriefingReconciler: Sendable {
    var calendar: Calendar = .current
    /// Fraction of a record's title words the claim has to mention.
    var minimumMatchScore = 0.5

    func reconcile(_ claims: [BriefingDateClaim], against records: [Evidence]) -> BriefingReport {
        var report = BriefingReport()

        for claim in claims {
            guard let record = bestMatch(for: claim, in: records),
                  let recordDate = record.facts.dueDate ?? record.facts.startDate else {
                report.unmatched.append(claim)
                continue
            }

            if agrees(claim, with: recordDate) {
                report.confirmations.append(BriefingConfirmation(claim: claim, record: record))
            } else {
                report.conflicts.append(BriefingConflict(claim: claim, record: record, recordDate: recordDate))
            }
        }

        // The same announcement can repeat a date; keep one conflict per announcement and record.
        var seen = Set<String>()
        report.conflicts = report.conflicts.filter { seen.insert("\($0.claim.source.id)|\($0.record.id)").inserted }

        return report
    }

    func agrees(_ claim: BriefingDateClaim, with recordDate: Date) -> Bool {
        claim.hasTime
            ? calendar.isDate(claim.date, equalTo: recordDate, toGranularity: .minute)
            : calendar.isDate(claim.date, inSameDayAs: recordDate)
    }

    func bestMatch(for claim: BriefingDateClaim, in records: [Evidence]) -> Evidence? {
        let courseID = claim.source.ref.courseID
        let claimTerms = Self.terms(in: claim.itemMentioned).union(Self.terms(in: claim.quote))

        let scored = records
            .filter { $0.ref.courseID == courseID && $0.ref.kind != .announcement }
            .map { (record: $0, score: score(title: $0.title, claimTerms: claimTerms)) }
            .filter { $0.score >= minimumMatchScore }
            .sorted { $0.score > $1.score }

        guard let best = scored.first else { return nil }
        if scored.count > 1 && scored[1].score == best.score {
            return nil
        }

        return best.record
    }

    func score(title: String, claimTerms: Set<String>) -> Double {
        let titleTerms = Self.terms(in: title)
        guard !titleTerms.isEmpty else { return 0 }

        // "Lab 2" must not match a claim about "Lab 3".
        let numbers = titleTerms.filter { $0.allSatisfy(\.isNumber) }
        guard numbers.isSubset(of: claimTerms) else { return 0 }

        return Double(titleTerms.intersection(claimTerms).count) / Double(titleTerms.count)
    }

    private static let ignoredWords: Set<String> = [
        "the", "and", "for", "now", "due", "will", "this", "that", "with", "your", "you", "are",
        "has", "have", "been", "from", "our", "its", "into", "instead", "of", "to", "on", "at",
        "is", "be", "an", "a", "in", "by"
    ]

    /// Lowercased words, numbers kept on their own ("Lab 2:" → lab, 2).
    static func terms(in text: String) -> Set<String> {
        Set(
            text.lowercased()
                .split { !$0.isLetter && !$0.isNumber }
                .map(String.init)
                .filter { !ignoredWords.contains($0) && ($0.count > 1 || $0.allSatisfy(\.isNumber)) }
        )
    }
}
