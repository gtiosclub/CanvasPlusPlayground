//
//  TodayWidget.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 10/19/25.
//

import SwiftUI

struct TodayWidget: @MainActor ListWidget {
    static var widgetID: String { "today" }
    static var displayName: String { "Today" }
    static var description: String { "See what's overdue, what's due in the next 48 hours, and today's calendar events." }
    static var systemImage: String { "calendar.badge.clock" }
    static var color: Color { .blue }
    static var allowedSizes: [WidgetSize] { [.small, .medium, .large] }

    var title: String { "Today" }
    var destination: NavigationModel.Destination = .today

    @MainActor
    var dataSource: TodayDataSource = .init()

    var contents: some View {
        TodayWidgetContents(dataSource: dataSource, size: .medium)
    }

    func adaptedContents(for size: WidgetSize) -> AnyView {
        AnyView(TodayWidgetContents(dataSource: dataSource, size: size))
    }
}

/// Small: a count per section. Medium: the next few items across sections.
/// Large: items grouped by section with "+N more".
private struct TodayWidgetContents: View {
    @Environment(\.isWidgetNavigationEnabled) private var isWidgetNavigationEnabled

    let dataSource: TodayDataSource
    let size: WidgetSize

    var body: some View {
        Group {
            switch size {
            case .small:
                counts
            case .medium:
                nextItems
            case .large:
                sections
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .overlay {
            if dataSource.isEmpty {
                Text("Nothing due")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Small

    private var counts: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(visibleSections, id: \.self) { section in
                HStack(spacing: 6) {
                    Image(systemName: section.systemImage)
                        .foregroundStyle(section.color)
                        .frame(width: 22)

                    switch dataSource.state(for: section) {
                    case .failed:
                        Text("Couldn't load")
                            .foregroundStyle(.secondary)
                    default:
                        Text("\(dataSource.items(in: section).count) \(section.countLabel)")
                    }
                }
                .font(.subheadline)
                .bold()
            }

            Spacer()
        }
    }

    // MARK: Medium

    private var nextItems: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(dataSource.widgetData.prefix(3))) { item in
                row(for: item, section: section(of: item))
            }

            failedSectionsNote

            Spacer()
        }
    }

    // MARK: Large

    private var sections: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(visibleSections, id: \.self) { section in
                let items = dataSource.items(in: section)
                let limit = 2

                VStack(alignment: .leading, spacing: 4) {
                    Text(section.title)
                        .font(.caption)
                        .bold()
                        .foregroundStyle(section.color)

                    if case .failed = dataSource.state(for: section) {
                        Text("Couldn't load")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if items.isEmpty {
                        Text(section.emptyMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(items.prefix(limit)) { item in
                            row(for: item, section: section)
                        }

                        if items.count > limit {
                            Text("+\(items.count - limit) more")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()
        }
    }

    // MARK: Helpers

    /// Overdue is hidden when there's nothing overdue, same as on the Today screen.
    private var visibleSections: [TodaySection] {
        TodaySection.allCases.filter { section in
            section != .overdue
                || dataSource.state(for: .overdue) != .loaded
                || !dataSource.overdueItems.isEmpty
        }
    }

    @ViewBuilder
    private var failedSectionsNote: some View {
        // Overdue and Due Soon come from the same to-do request, so they fail together.
        let failed = [
            (dataSource.todoState, "to-dos"),
            (dataSource.calendarEventState, "calendar events")
        ]
        .compactMap { state, name -> String? in
            if case .failed = state { return name }
            return nil
        }

        if !failed.isEmpty {
            Text("Couldn't load \(failed.joined(separator: " or "))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func section(of item: ListWidgetData) -> TodaySection {
        TodaySection.allCases.first { dataSource.items(in: $0).contains(item) } ?? .dueSoon
    }

    @ViewBuilder
    private func row(for item: ListWidgetData, section: TodaySection) -> some View {
        let label = HStack(alignment: .top, spacing: 6) {
            Circle()
                .fill(section.color)
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .bold()
                    .lineLimit(1)

                Text(item.description)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(section == .overdue ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
            }

            Spacer(minLength: 0)
        }
        .contentShape(.rect)

        if isWidgetNavigationEnabled {
            NavigationLink(value: dataSource.destinationView(for: item)) {
                label
            }
            .buttonStyle(.plain)
        } else {
            label
        }
    }
}

private extension TodaySection {
    var countLabel: String {
        switch self {
        case .overdue:
            "overdue"
        case .dueSoon:
            "due soon"
        case .calendarEvents:
            "events"
        }
    }
}
