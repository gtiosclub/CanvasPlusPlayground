//
//  BriefingCardTests.swift
//  CanvasPlusPlaygroundTests
//

import Foundation
import Testing
@testable import CanvasPlusPlayground

private let announcement = Evidence(
    ref: .announcement(id: "a1", courseID: "1"),
    title: "Project 2 update",
    snippet: "Project 2 is now due Friday.",
    facts: EvidenceFacts(postedAt: Date(timeIntervalSince1970: 1_790_000_000))
)

private func project(_ id: String, due: TimeInterval) -> Evidence {
    Evidence(ref: .assignment(id: id, courseID: "1"), title: "Project \(id)", snippet: nil, facts: EvidenceFacts(dueDate: Date(timeIntervalSince1970: due)))
}

private func conflict(_ record: Evidence) -> BriefingConflict {
    let claim = BriefingDateClaim(
        source: announcement,
        itemMentioned: record.title,
        date: Date(timeIntervalSince1970: 1_790_500_000),
        hasTime: false,
        quote: "Project 2 is now due Friday.",
        extractedBy: "none"
    )
    return BriefingConflict(claim: claim, record: record, recordDate: record.facts.dueDate!)
}

/// Resolves only the refs it was given.
@MainActor
private final class FixedResolver: EvidenceResolver {
    let known: [String: Evidence]
    init(_ evidence: [Evidence]) { known = Dictionary(uniqueKeysWithValues: evidence.map { ($0.id, $0) }) }
    func resolve(_ ref: EvidenceRef) async -> Evidence? { known[ref.id] }
}

struct BriefingCardTests {
    @Test func conflictsComeFirstSoonestFirstThenChangesNewestFirst() {
        let later = project("2", due: 1_790_900_000)
        let sooner = project("3", due: 1_790_100_000)
        let report = BriefingReport(conflicts: [conflict(later), conflict(sooner)])
        let changes = [
            BriefingChange(id: "c1", title: "Old", detail: "", evidence: [], detectedAt: Date(timeIntervalSince1970: 1)),
            BriefingChange(id: "c2", title: "New", detail: "", evidence: [], detectedAt: Date(timeIntervalSince1970: 2)),
        ]

        let cards = BriefingCardBuilder.cards(report: report, changes: changes)
        #expect(cards.map(\.title) == ["Date mismatch: Project 3", "Date mismatch: Project 2", "New", "Old"])
        #expect(cards[0].evidence.map(\.id) == ["assignment:3", "announcement:a1"])
    }

    @Test func noReportAndNoChangesMeansNoCards() {
        #expect(BriefingCardBuilder.cards(report: nil, changes: []).isEmpty)
    }

    @Test func conflictCardsShowBothDatesAndTheQuote() throws {
        let card = try #require(BriefingCardBuilder.cards(report: BriefingReport(conflicts: [conflict(project("2", due: 1_790_000_000))]), changes: []).first)
        #expect(card.lines.count == 2)
        #expect(card.lines[0].hasPrefix("Announcement: "))
        #expect(card.lines[1].hasPrefix("Canvas: "))
        #expect(card.quote == "Project 2 is now due Friday.")
    }

    @Test @MainActor func aCardOnlyShowsOnceAllItsEvidenceResolves() async {
        let record = project("2", due: 1_790_000_000)
        let card = BriefingCardBuilder.cards(report: BriefingReport(conflicts: [conflict(record)]), changes: [])[0]

        let moved = project("2", due: 1_790_200_000)
        let resolved = await BriefingCardBuilder.resolve(card, with: FixedResolver([moved, announcement]))
        #expect(resolved?.evidence.first?.facts.dueDate == moved.facts.dueDate)

        // The assignment was deleted: no card.
        #expect(await BriefingCardBuilder.resolve(card, with: FixedResolver([announcement])) == nil)
    }
}
