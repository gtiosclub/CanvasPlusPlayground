//
//  CalendarView.swift
//  CanvasPlusPlayground
//
//  Created by Jiyoon Lee on 9/19/24.
//

import SwiftUI

struct CalendarView: View {
    let icsURL: URL?

    @State private var events = [CanvasCalendarEventGroup]()

    init(course: Course) {
        self.icsURL = URL(string: course.calendar?.ics ?? "")
    }

    var body: some View {
        VStack {
            List {
                ForEach(events) { eventGroup in
                    Section(eventGroup.displayDate) {
                        ForEach(eventGroup.events) { event in
                            EventRow(event: event)
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
        .task {
            events = await ICSParser.parseEvents(from: icsURL)
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
        .navigationTitle("Calendar")
    }
}

private struct EventRow: View {
    let event: CanvasCalendarEvent

    var body: some View {
        HStack {
            Text(event.summary)
            Spacer()

            dateDetailText
                .foregroundStyle(.secondary)
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
