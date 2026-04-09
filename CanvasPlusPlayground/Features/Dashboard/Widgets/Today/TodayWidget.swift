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
    static var description: String { "View all your todos, announcements, and calendar events for today in one place." }
    static var systemImage: String { "calendar.badge.clock" }
    static var color: Color { .blue }
    static var allowedSizes: [WidgetSize] { [.small, .medium, .large] }

    var title: String { "Today" }
    var destination: NavigationModel.Destination = .today

    @MainActor
    var dataSource: TodayDataSource = .init()

    func adaptedContents(for size: WidgetSize) -> AnyView {
        AnyView(TodayWidgetBodyView(widget: self))
    }
}

private struct TodayWidgetBodyView: View {
    let widget: TodayWidget

    private var dataSource: TodayWidget.DataSource { widget.dataSource }

    var body: some View {
        Group {
            if dataSource.widgetData.isEmpty {
                ContentUnavailableView(
                    "All Clear for Today! 🎉",
                    systemImage: "calendar.badge.checkmark",
                    description: Text("Today’s looking light. Kick back and enjoy it")
                )
            } else {
                List {
                    Section {
                        if !dataSource.todoItems.isEmpty {
                            ForEach(dataSource.todoItems) { item in
                                NavigationLink(value: dataSource.destinationView(for: item)) {
                                    TodayItemRow(item: item)
                                }
                            }
                        } else {
                            Text("No to-do items")
                                .foregroundStyle(.secondary)
                                .font(.callout)
                        }
                    } header: {
                        Label("To-Do Items", systemImage: "checklist")
                            .font(.headline)
                            .foregroundStyle(.red)
                    }

                    Section {
                        if !dataSource.calendarEventItems.isEmpty {
                            ForEach(dataSource.calendarEventItems) { item in
                                NavigationLink(value: dataSource.destinationView(for: item)) {
                                    TodayItemRow(item: item)
                                }
                            }
                        } else {
                            Text("No calendar events")
                                .foregroundStyle(.secondary)
                                .font(.callout)
                        }
                    } header: {
                        Label("Calendar Events", systemImage: "calendar")
                            .font(.headline)
                            .foregroundStyle(.purple)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

}
