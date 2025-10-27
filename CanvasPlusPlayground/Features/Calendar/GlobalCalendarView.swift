//
//  GlobalCalendarView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/26/25.
//

import SwiftUI

struct GlobalCalendarView: View {
    @Environment(GlobalCalendarManager.self) var calendarManager
    @Environment(CourseManager.self) var courseManager

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(calendarManager.currentWeekDates.enumerated()), id: \.element) { index, date in
                if index > 0 {
                    Divider()
                }
                DayColumn(date: date, events: calendarManager.calendarEvents.filter { event in
                    Calendar.current.isDate(event.startDate, inSameDayAs: date)
                }, backgroundTint: Calendar.current.isDateInToday(date) ? .blue.opacity(0.15) : nil)
            }
        }
        .task {
            await calendarManager.getCalendarEventsForCourses(courses: courseManager.activeCourses)
        }
        .toolbar {
            ToolbarItem {
                Button("Previous Week", systemImage: "chevron.left", action: calendarManager.decrementWeek)
            }
            ToolbarItem {
                Button("Next Week", systemImage: "chevron.right", action: calendarManager.incrementWeek)
            }
            ToolbarItem {
                Button("Current", action: calendarManager.setToNow)
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
            NavigationLink(value: NavigationModel.Destination.calendarEvent(event, event.course)) {
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
            .buttonStyle(.plain)
        }
    }
}
