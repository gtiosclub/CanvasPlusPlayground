//
//  CombinedCalendarManager.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/25/25.
//

import Foundation


@Observable
class CombinedCalendarManager {

    var calendarEvents: [CanvasCalendarEventGroup] = []

    func getCalendarEventsForCourses(courses: [Course]) async {

        let gtScheduler = GTSchedulerParser.shared
        

        calendarEvents = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var allEventGroups: [CanvasCalendarEventGroup] = []

        for course in courses {
            
            let courseSchedule = try? await gtScheduler.getCanvasCourseScheduleMeetings(course: course) // TODO: ERROR HANDLING
            guard let courseSchedule = courseSchedule else { continue }

            // Dictionary to collect CanvasCalendarEvents grouped by date
            var eventsByDate: [Date: [CanvasCalendarEvent]] = [:]

            // For the next 21 days (3 weeks) starting today
            for dayOffset in 0..<21 {
                guard let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
                let weekday = calendar.component(.weekday, from: currentDate) // Sunday=1 ... Saturday=7

                for meeting in courseSchedule.meetings {
                    // Check if currentDate weekday matches meeting.weekday (which is Locale.Weekday)
                    if weekday == meeting.weekday.number(calendar: calendar) {
                        // Construct startDate and endDate by combining currentDate with meeting startTime/endTime
                        var startComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
                        startComponents.hour = meeting.startTime.hour
                        startComponents.minute = meeting.startTime.minute
                        startComponents.second = 0

                        var endComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
                        endComponents.hour = meeting.endTime.hour
                        endComponents.minute = meeting.endTime.minute
                        endComponents.second = 0

                        guard let startDate = calendar.date(from: startComponents),
                              let endDate = calendar.date(from: endComponents) else { continue }

                        // Create CanvasCalendarEvent
                        let event = CanvasCalendarEvent(
                            id: UUID().uuidString,
                            course: course,
                            summary: course.displayName,
                            startDate: startDate,
                            endDate: endDate,
                            location: meeting.location
                        )

                        // Append this event to eventsByDate for currentDate
                        if eventsByDate[currentDate] != nil {
                            eventsByDate[currentDate]?.append(event)
                        } else {
                            eventsByDate[currentDate] = [event]
                        }
                    }
                }
            }

            // For each date with events, create a CanvasCalendarEventGroup and add to allEventGroups
            for (date, events) in eventsByDate {
                let eventGroup = CanvasCalendarEventGroup(date: date, events: events)
                allEventGroups.append(eventGroup)
            }
        }

        // Assign the accumulated event groups to calendarEvents
        calendarEvents = allEventGroups
    }
}


extension Locale.Weekday {
    func number(calendar: Calendar) -> Int {
        // Map Locale.Weekday to Calendar weekday number (1 for Sunday...7 for Saturday)
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        default: return 1 // Fallback to Sunday
        }
    }
}
