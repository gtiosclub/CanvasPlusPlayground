//
//  BriefingCard.swift
//  CanvasPlusPlayground
//

import Foundation
import SwiftData

/// One card in the dashboard briefing. Every card is something Swift worked out from records
/// (no model writes card text), so all of them also work at Tier 0.
struct BriefingCard: Identifiable, Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        /// An announcement gives a different date than the Canvas record (#586).
        case dateConflict(BriefingConflict)
        /// Something changed on Canvas since the student last looked (#523).
        case change(BriefingChange)
    }

    let kind: Kind
    /// The records the card is about. A card is only shown once all of them re-read.
    var evidence: [Evidence]

    var id: String {
        switch kind {
        case .dateConflict(let conflict): "conflict|\(conflict.id)"
        case .change(let change): "change|\(change.id)"
        }
    }

    var title: String {
        switch kind {
        case .dateConflict(let conflict): "Date mismatch: \(conflict.record.title)"
        case .change(let change): change.title
        }
    }

    var systemImage: String {
        switch kind {
        case .dateConflict: "calendar.badge.exclamationmark"
        case .change: "arrow.triangle.2.circlepath"
        }
    }

    /// Plain lines under the title.
    var lines: [String] {
        switch kind {
        case .dateConflict(let conflict):
            [
                "Announcement: \(Self.format(conflict.claim.date, hasTime: conflict.claim.hasTime))",
                "Canvas: \(Self.format(conflict.recordDate, hasTime: conflict.claim.hasTime))",
            ]
        case .change(let change):
            [change.detail]
        }
    }

    var quote: String? {
        if case .dateConflict(let conflict) = kind { conflict.claim.quote } else { nil }
    }

    private static func format(_ date: Date, hasTime: Bool) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour(hasTime ? .defaultDigits(amPM: .abbreviated) : .omitted).minute(hasTime ? .twoDigits : .omitted))
    }
}

/// A change to a Canvas record since the student last looked. Filled in by #523's change
/// tracking through `BriefingChangeSource`; until that lands the source returns none.
struct BriefingChange: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    /// e.g. "Due date changed: Oct 3 → Oct 5".
    let detail: String
    let evidence: [Evidence]
    let detectedAt: Date
}

/// Where change cards come from. #523 provides the real one.
@MainActor
protocol BriefingChangeSource {
    func unseenChanges() async -> [BriefingChange]
}

struct NoBriefingChanges: BriefingChangeSource {
    func unseenChanges() async -> [BriefingChange] { [] }
}

/// A card whose evidence re-read, with where each evidence chip goes.
struct ResolvedBriefingCard: Identifiable, Hashable {
    let card: BriefingCard
    let destinations: [String: NavigationModel.Destination]

    var id: String { card.id }
}

enum BriefingCardBuilder {
    /// Conflict cards first (soonest Canvas date first), then changes (newest first).
    static func cards(report: BriefingReport?, changes: [BriefingChange]) -> [BriefingCard] {
        let conflicts = (report?.conflicts ?? [])
            .sorted { $0.recordDate < $1.recordDate }
            .map { BriefingCard(kind: .dateConflict($0), evidence: [$0.record, $0.claim.source]) }
        let changeCards = changes
            .sorted { $0.detectedAt > $1.detectedAt }
            .map { BriefingCard(kind: .change($0), evidence: $0.evidence) }
        return conflicts + changeCards
    }

    /// The card with its evidence re-read, or nil if any of it no longer exists. Cards for
    /// deleted assignments or announcements never show.
    @MainActor
    static func resolve(_ card: BriefingCard, with resolver: any EvidenceResolver) async -> BriefingCard? {
        var current: [Evidence] = []
        for evidence in card.evidence {
            guard let reread = await resolver.resolve(evidence.ref) else { return nil }
            current.append(reread)
        }
        var resolved = card
        resolved.evidence = current
        return resolved
    }

    /// Where each evidence chip should open, looked up in the cache.
    @MainActor
    static func destinations(for evidence: [Evidence], in context: ModelContext) -> [String: NavigationModel.Destination] {
        var destinations: [String: NavigationModel.Destination] = [:]

        for item in evidence {
            let id = item.ref.recordID
            switch item.ref {
            case .assignment:
                if let assignment = try? context.fetch(FetchDescriptor<Assignment>(predicate: #Predicate { $0.id == id })).first {
                    destinations[item.id] = .assignment(assignment)
                }
            case .announcement:
                if let topic = try? context.fetch(FetchDescriptor<DiscussionTopic>(predicate: #Predicate { $0.id == id })).first {
                    destinations[item.id] = .announcement(topic)
                }
            case .course:
                if let course = try? context.fetch(FetchDescriptor<Course>(predicate: #Predicate { $0.id == id })).first {
                    destinations[item.id] = .course(course)
                }
            case .calendarEvent:
                // Events aren't cached as models; open the calendar.
                destinations[item.id] = .allCalendar
            case .toDo:
                destinations[item.id] = .allToDos
            case .file:
                break
            }
        }
        return destinations
    }
}
