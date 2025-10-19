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
        #if os(iOS)
        .navigationTitle("Calendar")

        #else
        .navigationTitle("\(course.displayName) -- Calendar")
        #endif
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


