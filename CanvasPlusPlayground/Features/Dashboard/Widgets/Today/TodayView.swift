//
//  TodayView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 10/19/25.
//


import SwiftUI

#Preview {
    TodayView()
        .environment(CourseManager())
}

struct TodayView: View {
    @Environment(CourseManager.self) private var courseManager

    @State private var dataSource = TodayDataSource()
    @State private var isLoading = false

    private var todayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }

    var body: some View {
        if dataSource.widgetData.isEmpty && !isLoading {
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
        }
    }

    private func loadItems() async {
        isLoading = true
        try? await dataSource.fetchData(context: WidgetContext.shared)
        isLoading = false
    }
}

struct TodayItemRow: View {
    let item: ListWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .bold()
                .lineLimit(2)

            Text(item.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
