//
//  BriefingWidget.swift
//  CanvasPlusPlayground
//

import SwiftData
import SwiftUI

/// Builds the briefing cards from the latest report, one at a time: a card appears only once
/// all of its evidence re-reads, and a rippling placeholder stands in while it does.
@MainActor
@Observable
final class BriefingFeed {
    static let shared = BriefingFeed()

    private(set) var cards: [ResolvedBriefingCard] = []
    /// Cards still being checked.
    private(set) var pendingCount = 0
    private(set) var lastBuilt: Date?
    /// Whether the cards came from the model or from basic date detection.
    private(set) var usedModel = false

    var changeSource: any BriefingChangeSource = NoBriefingChanges()

    func rebuild(courseManager: CourseManager, toDoListManager: ToDoListManager) async {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let finder = BriefingConflictFinder.shared
        let candidates = BriefingCardBuilder.cards(report: finder.report, changes: await changeSource.unseenChanges())
        let resolver = DataSourceEvidenceResolver(
            dataSource: CanvasCacheAgentDataSource(courseManager: courseManager, toDoListManager: toDoListManager)
        )

        usedModel = finder.lastTier == .onDevice
        pendingCount = candidates.count
        var built: [ResolvedBriefingCard] = []

        for candidate in candidates {
            if let card = await BriefingCardBuilder.resolve(candidate, with: resolver) {
                built.append(ResolvedBriefingCard(
                    card: card,
                    destinations: BriefingCardBuilder.destinations(for: card.evidence, in: .shared)
                ))
                cards = built
            }
            pendingCount -= 1
        }

        cards = built
        pendingCount = 0
        lastBuilt = .now
    }
}

struct BriefingWidget: @MainActor GenericWidget {
    static var widgetID: String { "briefing" }
    static var displayName: String { "Briefing" }
    static var description: String { "Dates in announcements that don't match Canvas, and other things to check, with links to the source." }
    static var systemImage: String { "text.badge.checkmark" }
    static var color: Color { .indigo }
    static var allowedSizes: [WidgetSize] { [.medium, .large] }

    var title: String { "Briefing" }
    var destination: NavigationModel.Destination = .today

    @MainActor
    var dataSource = BriefingWidgetDataSource()

    var contents: some View {
        BriefingCardsView(limit: 2)
    }

    func adaptedContents(for size: WidgetSize) -> AnyView {
        AnyView(BriefingCardsView(limit: size == .large ? 4 : 2))
    }
}

@Observable
final class BriefingWidgetDataSource: GenericWidgetDataSource {
    var widgetData: [ResolvedBriefingCard] = []
    var fetchStatus: WidgetFetchStatus = .loading

    @MainActor
    func fetchData(context: WidgetContext) async throws {
        guard let courseManager = context.courseManager else {
            fetchStatus = .error
            return
        }
        await BriefingFeed.shared.rebuild(courseManager: courseManager, toDoListManager: ToDoListManager())
        widgetData = BriefingFeed.shared.cards
        fetchStatus = .loaded
    }

    func destinationView(for data: ResolvedBriefingCard) -> NavigationModel.Destination {
        data.destinations[data.card.evidence.first?.id ?? ""] ?? .today
    }
}

/// The cards, with a rippling placeholder for each one still being checked.
struct BriefingCardsView: View {
    var limit: Int

    private var feed: BriefingFeed { .shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(feed.cards.prefix(limit)) { card in
                BriefingCardView(card: card)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            ForEach(0..<min(feed.pendingCount, max(limit - feed.cards.count, 0)), id: \.self) { _ in
                PendingCard()
            }

            if feed.cards.isEmpty && feed.pendingCount == 0 {
                Label(feed.lastBuilt == nil ? "Checking announcements…" : "Nothing to check. Announcements match Canvas.", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .animation(.easeOut(duration: 0.25), value: feed.cards.map(\.id))
    }
}

private struct BriefingCardView: View {
    let card: ResolvedBriefingCard

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(card.card.title, systemImage: card.card.systemImage)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            ForEach(card.card.lines, id: \.self) { line in
                Text(line).font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                ForEach(card.card.evidence) { evidence in
                    ProvenanceChip(evidence: evidence, destination: card.destinations[evidence.id])
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }
}

/// A source chip that opens its record.
private struct ProvenanceChip: View {
    @Environment(\.isWidgetNavigationEnabled) private var isNavigationEnabled

    let evidence: Evidence
    let destination: NavigationModel.Destination?

    var body: some View {
        let label = Label(evidence.title, systemImage: icon)
            .font(.caption2)
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.tint.opacity(0.12), in: Capsule())

        if let destination, isNavigationEnabled {
            NavigationLink(value: destination) { label }
                .buttonStyle(.plain)
        } else {
            label
        }
    }

    private var icon: String {
        switch evidence.ref.kind {
        case .announcement: "megaphone"
        case .assignment: "doc.text"
        case .calendarEvent: "calendar"
        default: "link"
        }
    }
}

/// Placeholder that ripples until its card's evidence resolves.
private struct PendingCard: View {
    @State private var pulse = false
    @State private var center = CGPoint.zero

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.secondary.opacity(0.15))
            .frame(height: 52)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { center = CGPoint(x: $0.width / 2, y: $0.height / 2) }
            .rippleEffect(origin: center, condition: pulse)
            .task {
                while !Task.isCancelled {
                    pulse.toggle()
                    try? await Task.sleep(for: .seconds(1.2))
                }
            }
            .accessibilityLabel("Checking a briefing item")
    }
}
