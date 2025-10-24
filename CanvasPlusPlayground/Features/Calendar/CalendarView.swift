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
            CalendarEventsView(events: events)
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
        events = await ICSParser.parseEvents(from: icsURL, for: course)
        isLoadingCalendar = false
    }
}
