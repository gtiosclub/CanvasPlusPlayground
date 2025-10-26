//
//  ICalView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/26/25.
//

import SwiftUI

struct CalendarWeekView: View {
    @Environment(CombinedCalendarManager.self) var calendarManager
    @Environment(CourseManager.self) var courseManager
    @State var currentDate: Date
    var allEvents: [CanvasCalendarEvent] { calendarManager.calendarEvents }

    private var currentWeekDates: [Date] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else {
            return [currentDate]
        }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: weekInterval.start)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(currentWeekDates.enumerated()), id: \.element) { index, date in
                if index > 0 {
                    Divider()
                }
                DayColumn(date: date, events: allEvents.filter { event in
                    Calendar.current.isDate(event.startDate, inSameDayAs: date)
                }, backgroundTint: Calendar.current.isDateInToday(date) ? .blue.opacity(0.15) : nil)
            }
        }
        .task {
            await calendarManager.getCalendarEventsForCourses(courses: courseManager.activeCourses)
        }
        .toolbar {
            ToolbarItem {
                Button {
                    if let newDate = Calendar.current.date(byAdding: .day, value: -7, to: currentDate) {
                        currentDate = newDate
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
            ToolbarItem {
                Button {
                    if let newDate = Calendar.current.date(byAdding: .day, value: 7, to: currentDate) {
                        currentDate = newDate
                    }
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            ToolbarItem {
                Button {
                    currentDate = Date()
                } label: {
                    Text("Current")
                }
                .accessibilityLabel("Go to current week")
            }
        }
    }

    private struct DayColumn: View {
        let date: Date
        let events: [CanvasCalendarEvent]
        let backgroundTint: Color?

        var body: some View {
            VStack {
                Text(date.dayNumberString)
                VStack(spacing: 5) {
                    ForEach(events) { event in
                        EventCardView(event: event)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(backgroundTint ?? .clear)
        }
    }

    private struct EventCardView: View {
        let event: CanvasCalendarEvent

        private var timeRangeString: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
        }

        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.summary)
                        .bold()
                    Text(timeRangeString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)


                    Text(event.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(5)
            .frame(maxWidth: .infinity)
            .background(.thinMaterial)
            .cornerRadius(8)
            .padding(.horizontal, 4)
        }
    }
}

extension Date {
    /// Returns the day abbreviation and day number as a string (e.g., "Mon 20").
    var dayNumberString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "E d" // e.g., "Mon 20"
        return formatter.string(from: self)
    }
}
