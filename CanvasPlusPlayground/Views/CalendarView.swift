//
//  CalendarView.swift
//  CanvasPlusPlayground
//
//  Created by Jiyoon Lee on 9/19/24.
//

import SwiftUI

struct CalendarView: View {
    @StateObject var calendarEvents = CalendarEventViewModel()
    let course: Course
    var sortedEvents: [(key: Date?, value: [CalendarEvent])] {
        calendarEvents.eventsByDate.sorted {
            ($0.key ?? Date.distantPast) < ($1.key ?? Date.distantPast)
        }
    }
    var body: some View {
        if let icsURL = course.calendar?.ics, let url = URL(string: icsURL) {
            List {
                ForEach(sortedEvents, id: \.key) { date, events in
                    EventSection(date: date, events: events)
                    
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let icsURL = course.calendar?.ics, let url = URL(string: icsURL) {
//                        Link(destination: url) {
//                            Image(systemName: "calendar")
//                        }
                        Link("Open in Calendar", destination: url)
                    }
                }
            }
            .onAppear {
                calendarEvents.fetchEvents(from: url) { result in
                    print(result)
                }
            }
        } else {
            Text("No calendar available")
                .navigationTitle("Calendar")
        }
    }
}

struct EventSection: View {
    let date: Date?
    let events: [CalendarEvent]
    
    var body: some View {
        Section(header: Text(date?.toDayMonthDay() ?? "No Date")) {
            ForEach(events) { event in
                EventDetails(event: event)
            }
        }
    }
}

struct EventDetails: View {
    let event: CalendarEvent

    var body: some View {
        VStack(alignment: .leading) {
            Text(event.eventName ?? "Unnamed Event")
                .foregroundColor(.primary)
            eventTimeText
        }
    }
    
    private var eventTimeText: some View {
        let startTime = event.startDate?.toHourMinute() ?? "No time"
        let endTime = event.endDate?.toHourMinute() ?? "No time"
        if startTime == endTime && startTime != "No time" {
            return Text(endTime).foregroundColor(.secondary)
        } else if startTime == "No time" && endTime == "No time" {
            return Text("All day")
                .foregroundColor(.secondary)
        } else if startTime == "No time" {
            return Text(endTime)
                .foregroundColor(.secondary)
        } else if endTime == "No time" {
            return Text(startTime)
                .foregroundColor(.secondary)
        } else {
            return Text("from \(startTime) to \(endTime)")
                .foregroundColor(.secondary)
        }
    }
}

extension Date {
    func toDayMonthDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        let dateString = formatter.string(from: self)
        let calendar = Calendar.current
        let day = calendar.component(.day, from: self)
        let suffix = ordinalSuffix(for: day)
        return dateString + suffix
    }

    func toHourMinute() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter.string(from: self).lowercased()
    }

    private func ordinalSuffix(for day: Int) -> String {
        let j = day % 10, k = day % 100
        if j == 1 && k != 11 {
            return "st"
        }
        if j == 2 && k != 12 {
            return "nd"
        }
        if j == 3 && k != 13 {
            return "rd"
        }
        return "th"
    }
    
    func allDates(till endDate: Date) -> [Date] {
        var date = self
        var dates = [date.stripTime()]
        let calendar = Calendar.current
        while date < endDate {
            date = calendar.date(byAdding: .day, value: 1, to: date)!
            dates.append(date.stripTime())
        }
        return dates
    }
    
    func stripTime() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        return calendar.date(from: components)!
    }
}
