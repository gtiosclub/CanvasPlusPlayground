//
//  CalendarView.swift
//  CanvasPlusPlayground
//
//  Created by Jiyoon Lee on 9/19/24.
//

import SwiftUI

struct CalendarView: View {
    let icsURL: URL?
    let course: Course
    @State private var events = [CanvasCalendarEventGroup]()

    @State private var isLoadingCalendar = true

    init(course: Course) {
        self.course = course
        self.icsURL = URL(string: course.calendarIcs ?? "")
    }

    var body: some View {
        VStack {
            List {
                ForEach(events) { eventGroup in
                    Section(eventGroup.displayDate) {
                        ForEach(eventGroup.events) { event in
                            EventLinkRow(event: event, course: course)
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
        .task {
            await loadCalendar()
        }
        .overlay {
            if events.isEmpty {
                ContentUnavailableView("No events found", systemImage: "calendar.badge.exclamationmark")
            }
        }
        .toolbar {
            if let icsURL {
                ToolbarItem(placement: .primaryAction) {
                    Link(destination: icsURL) {
                        Label("Open in Calendar", systemImage: "calendar")
                    }
                }
            }
        }
        .statusToolbarItem("Calendar", isVisible: isLoadingCalendar)
        .navigationTitle("Calendar")
    }

    private func loadCalendar() async {
        isLoadingCalendar = true
        events = await ICSParser.parseEvents(from: icsURL)
        isLoadingCalendar = false
    }
}

private struct EventLinkRow: View {
    let event: CanvasCalendarEvent
    let course: Course

    var body: some View {
        NavigationLink(value: NavigationModel.Destination.calendarEvent(event, course)) {
            EventRow(event: event)
        }
        .contextMenu {
            PinButton(
                itemID: event.id,
                courseID: course.id,
                type: .calendarEvent
            )
            NewWindowButton(destination: .calendarEvent(event, course))
        }
        .swipeActions(edge: .leading) {
            PinButton(
                itemID: event.id,
                courseID: course.id,
                type: .calendarEvent
            )
        }
    }
}

private struct EventRow: View {
    let event: CanvasCalendarEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.summary)
                .lineLimit(2)

            dateDetailText
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var dateDetailText: Text {
        if event.startDate == event.endDate {
            Text(event.startDate, style: .time)
        } else {
            Text(event.startDate, style: .time) + Text(" - ") + Text(event.endDate, style: .time)
        }
    }
}


struct CalendarEventDetailView: View {
    let event: CanvasCalendarEvent
    let course: Course?

    private var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let startTime = formatter.string(from: event.startDate)
        let endTime = formatter.string(from: event.endDate)
        return "\(startTime) - \(endTime)"
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: event.startDate)
    }

    private var duration: String {
        let interval = event.endDate.timeIntervalSince(event.startDate)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var body: some View {
        Form {
            // Course Section (if available)
            if let course {
                Section {
                    HStack {
                        if let color = course.rgbColors?.color {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color)
                                .frame(width: 4)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(course.displayName)
                                .font(.headline)

                            if let courseCode = course.courseCode {
                                Text(courseCode)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }

            // Event Details Section
            Section("Event Details") {
                LabeledContent("Title", value: event.summary)

                LabeledContent("Date", value: dateString)

                LabeledContent("Time", value: timeRangeString)

                LabeledContent("Duration", value: duration)

                if event.location != "-" {
                    LabeledContent("Location", value: event.location)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Event")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
