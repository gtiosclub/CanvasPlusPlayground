//  CalendarEventsView.swift
//  CanvasPlusPlayground
//
//  Extracted generic event display for reuse

import SwiftUI

extension Date {
    func startOfDay(using calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: self)
    }
}

struct CalendarEventsView: View {
    let events: [CanvasCalendarEventGroup]
    
    var body: some View {
        // Flatten all events from all groups
        let allEvents = events.flatMap { $0.events }
        // Group by day
        let grouped = Dictionary(grouping: allEvents) { $0.startDate.startOfDay() }
        // Sorted unique days
        let sortedDays = grouped.keys.sorted()
        
        return List {
            ForEach(sortedDays, id: \.self) { day in
                Section(header: Text(day.formatted(date: .abbreviated, time: .omitted))) {
                    let events = grouped[day]?.sorted { first, second in
                        first.startDate < second.startDate
                    } ?? []
                    ForEach(events) { event in
                        EventLinkRow(event: event)
                    }
                }
            }
        }
        .listStyle(.inset)
    }
}

// Pull in EventLinkRow and EventRow as private.
private struct EventLinkRow: View {
    let event: CanvasCalendarEvent

    var body: some View {
        NavigationLink(value: NavigationModel.Destination.calendarEvent(event, event.course)) {
            EventRow(event: event)
        }
        .contextMenu {
            PinButton(
                itemID: event.id,
                courseID: event.course.id,
                type: .calendarEvent
            )
            NewWindowButton(destination: .calendarEvent(event, event.course))
        }
        .swipeActions(edge: .leading) {
            PinButton(
                itemID: event.id,
                courseID: event.course.id,
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

