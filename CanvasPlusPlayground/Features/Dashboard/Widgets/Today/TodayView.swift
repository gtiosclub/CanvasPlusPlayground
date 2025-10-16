//
//  TodayView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 10/11/25.
//

import SwiftUI

struct TodayView: View {
    @Environment(CourseManager.self) private var courseManager
    @Environment(NavigationModel.self) private var navigationModel
    @State private var todayManager = TodayWidgetManager()
    @State private var isLoading = false
    @State private var selectedItem: AnyHashable?

    private var todayString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        return dateFormatter.string(from: Date())
    }

    var body: some View {
        List(selection: $selectedItem) {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(todayString)
                        .font(.title2)
                        .fontWeight(.bold)

                    if todayManager.fetchStatus == .loaded {
                        Text("Your schedule for today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }


            if !todayManager.todayEvents.isEmpty {
                Section("Calendar Events") {
                    ForEach(todayManager.todayEvents) { courseEvent in
                        NavigationLink(value: NavigationModel.Destination.calendarEvent(courseEvent.event, courseEvent.course)) {
                            CalendarEventRow(courseEvent: courseEvent)
                        }
                    }
                }
            }

            if !todayManager.todayAnnouncements.isEmpty {
                Section("Announcements") {
                    ForEach(todayManager.todayAnnouncements, id: \.id) { courseAnnouncement in
                        NavigationLink(value: NavigationModel.Destination.announcement(courseAnnouncement.announcement)) {
                            AnnouncementRow(
                                course: courseAnnouncement.course,
                                announcement: courseAnnouncement.announcement,
                                showCourseName: true
                            )
                        }
                    }
                }
            }

            if !todayManager.todayAssignments.isEmpty {
                Section("Assignments Due Today") {
                    ForEach(todayManager.todayAssignments) { assignment in
                        if let destination = assignment.navigationDestination() {
                            NavigationLink(value: destination) {
                                AssignmentRow(assignment: assignment)
                            }
                        }
                    }
                }
            }
        }
        .overlay {
            if todayManager.fetchStatus == .loaded &&
               todayManager.todayEvents.isEmpty &&
               todayManager.todayAnnouncements.isEmpty &&
               todayManager.todayAssignments.isEmpty {
                ContentUnavailableView(
                    "No Events Today",
                    systemImage: "sun.max",
                    description: Text("Enjoy your free day!")
                )
            }
        }
        .navigationTitle("Today")
#if os(iOS)
        .listStyle(.insetGrouped)
#else
        .listStyle(.inset)
#endif
        #if os(iOS)
        .onAppear {
            selectedItem = nil
        }
        #endif
        .statusToolbarItem("Today", isVisible: isLoading)
        .task {
            await loadTodayData()
        }
        .refreshable {
            await loadTodayData()
        }
        .onChange(of: courseManager.activeCourses) { _, _ in
            Task {
                await loadTodayData()
            }
        }
    }

    private func loadTodayData() async {
        isLoading = true
        try? await todayManager.fetchData(context: WidgetContext.shared)
        isLoading = false
    }
}

private struct CalendarEventRow: View {
    @Environment(NavigationModel.self) private var navigationModel

    let courseEvent: TodayWidgetManager.CourseEvent

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: courseEvent.event.startDate)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            VStack(alignment: .leading, spacing: 4) {
                // Course name
                if let course = courseEvent.course {
                    Text(course.displayName.uppercased())
                        .font(.caption)
                        .foregroundStyle(course.rgbColors?.color ?? .blue)
                }

                Text(courseEvent.event.summary)
                    .font(.body)
                    .fontWeight(.semibold)

                Text(timeString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if courseEvent.event.location != "-" {
                    Label(courseEvent.event.location, systemImage: "location")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contextMenu {
            if let course = courseEvent.course {
                Button("Go to Course...", systemImage: "folder") {
                    navigationModel.navigationPath.append(NavigationModel.Destination.course(course))
                }
            }

            PinButton(
                itemID: courseEvent.event.id,
                courseID: courseEvent.course?.id,
                type: .calendarEvent
            )

            NewWindowButton(destination: .calendarEvent(courseEvent.event, courseEvent.course))
        }
        .swipeActions(edge: .leading) {
            PinButton(
                itemID: courseEvent.event.id,
                courseID: courseEvent.course?.id,
                type: .calendarEvent
            )
        }
    }
}

private struct AssignmentRow: View {
    let assignment: ToDoItem

    private var dueTimeString: String? {
        guard let dueDate = assignment.dueDate else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: dueDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let course = assignment.course {
                Text(course.displayName.uppercased())
                    .font(.caption)
                    .foregroundStyle(course.rgbColors?.color ?? .accentColor)
            }

            Text(assignment.title)
                .font(.body)
                .fontWeight(.semibold)

            if let dueTimeString {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("Due at \(dueTimeString)")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
