//
//  TodayView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 10/19/25.
//

import SwiftUI

struct TodayView: View {
    @Environment(CourseManager.self) private var courseManager

    @State private var dataSource = TodayDataSource()
    @State private var isLoading = false

    var body: some View {
        List {
            // Overdue only shows up when there's something overdue.
            if dataSource.state(for: .overdue) != .loaded || !dataSource.overdueItems.isEmpty {
                section(.overdue)
            }

            section(.dueSoon)

            section(.calendarEvents)
        }
        .listStyle(.inset)
        .navigationTitle("Today")
        .task {
            await loadItems()
        }
        .refreshable {
            await loadItems()
        }
        .onChange(of: courseManager.activeCourses) { _, _ in
            Task {
                await loadItems()
            }
        }
        .statusToolbarItem("Today", isVisible: isLoading)
        .overlay {
            if dataSource.isEmpty {
                ContentUnavailableView(
                    "Nothing for Today",
                    systemImage: "calendar.badge.checkmark",
                    description: Text("Nothing is overdue or due in the next 48 hours, and you have no events today.")
                )
            }
        }
    }

    private func section(_ section: TodaySection) -> some View {
        Section {
            switch dataSource.state(for: section) {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
            case .failed(let message):
                TodaySectionErrorRow(message: message) {
                    Task { await loadItems() }
                }
            case .loaded:
                let items = dataSource.items(in: section)
                if items.isEmpty {
                    Text(section.emptyMessage)
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(items) { item in
                        NavigationLink(value: dataSource.destinationView(for: item)) {
                            TodayItemRow(item: item, isOverdue: section == .overdue)
                        }
                    }
                }
            }
        } header: {
            Label(section.title, systemImage: section.systemImage)
                .font(.headline)
                .foregroundStyle(section.color)
        }
    }

    private func loadItems() async {
        isLoading = true
        try? await dataSource.fetchData(context: WidgetContext.shared)
        isLoading = false
    }
}

private struct TodayItemRow: View {
    let item: ListWidgetData
    var isOverdue = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .bold()
                .lineLimit(2)

            Text(item.description)
                .font(.caption)
                .foregroundStyle(isOverdue ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
        }
        .padding(.vertical, 4)
    }
}

private struct TodaySectionErrorRow: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        HStack {
            Label(message, systemImage: "exclamationmark.triangle")
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Retry", action: retry)
                .buttonStyle(.borderless)
        }
    }
}

extension TodaySection {
    var title: String {
        switch self {
        case .overdue:
            "Overdue"
        case .dueSoon:
            "Due Soon"
        case .calendarEvents:
            "Calendar Events"
        }
    }

    var systemImage: String {
        switch self {
        case .overdue:
            "exclamationmark.circle"
        case .dueSoon:
            "checklist"
        case .calendarEvents:
            "calendar"
        }
    }

    var color: Color {
        switch self {
        case .overdue:
            .red
        case .dueSoon:
            .orange
        case .calendarEvents:
            .purple
        }
    }

    var emptyMessage: String {
        switch self {
        case .overdue:
            "Nothing overdue"
        case .dueSoon:
            "Nothing due in the next 48 hours"
        case .calendarEvents:
            "No calendar events today"
        }
    }
}
