//
//  GlobalCalendarManager.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/25/25.
//

import Foundation
import SwiftUI

@Observable
class GlobalCalendarManager {

    var currentDate: Date = .now // currently displayed date

    enum DisplayMode { case compact, entireWeek }

    var displayMode: DisplayMode = .entireWeek

    // how much should the stepper move by (macOS: increment by week, iOS: increment by 2 day segments)
    var stepperIncrementCount: Int {

        return displayMode == .compact ? 2 : 7
    }

    // all dates currently displayed (macOS: entire week, iOS: just 2 days)
    var currentWeekDates: [Date] {

        if displayMode == .entireWeek {
            let calendar = Calendar.current
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else {
                return [currentDate]
            }
            return (0..<7).compactMap { offset in
                calendar.date(byAdding: .day, value: offset, to: weekInterval.start)
            }
        } else {
            // Returns the current date and the next date (2 consecutive days)
            let calendar = Calendar.current
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                return [currentDate]
            }
            return [currentDate, nextDate]
        }
    }

    var calendarEvents: [CanvasCalendarEvent] {
        return calendarEventGroups.flatMap { $0.events }
    }

    private var calendarEventGroups: [CanvasCalendarEventGroup] {
        weekAlignedEventsFromCourseSchedule // + ... (when you want to add more calendar events (like todos/etc, add them to this computed property
    }

    private var calendarEventsFromCourseSchedule: [CanvasCalendarEventGroup] = []


    private var weekAlignedEventsFromCourseSchedule: [CanvasCalendarEventGroup] {
        // Build a mapping: weekday number (Sunday=1 ... Saturday=7) -> date in current week
        let calendar = Calendar.current
        let weekDayToDate: [Int: Date] = Dictionary(uniqueKeysWithValues: currentWeekDates.map {
            (calendar.component(.weekday, from: $0), $0)
        })
        
        return calendarEventsFromCourseSchedule.compactMap { group in
            // Get the weekday of this group's date
            let groupWeekday = calendar.component(.weekday, from: group.date)
            guard let alignedDate = weekDayToDate[groupWeekday] else { return nil }
            
            // For each event, align its startDate and endDate to the new date
            let alignedEvents = group.events.map { event -> CanvasCalendarEvent in
                // Extract time components from original start/end dates
                let startTime = calendar.dateComponents([.hour, .minute, .second], from: event.startDate)
                let endTime = calendar.dateComponents([.hour, .minute, .second], from: event.endDate)
                
                // Build new start/end dates using the aligned date
                var startComponents = calendar.dateComponents([.year, .month, .day], from: alignedDate)
                startComponents.hour = startTime.hour
                startComponents.minute = startTime.minute
                startComponents.second = startTime.second
                let newStartDate = calendar.date(from: startComponents) ?? event.startDate
                
                var endComponents = calendar.dateComponents([.year, .month, .day], from: alignedDate)
                endComponents.hour = endTime.hour
                endComponents.minute = endTime.minute
                endComponents.second = endTime.second
                let newEndDate = calendar.date(from: endComponents) ?? event.endDate
                
                // Return a new CanvasCalendarEvent with adjusted dates
                return CanvasCalendarEvent(
                    id: event.id,
                    course: event.course,
                    summary: event.summary,
                    startDate: newStartDate,
                    endDate: newEndDate,
                    location: event.location
                )
            }
            
            return CanvasCalendarEventGroup(date: alignedDate, events: alignedEvents)
        }
    }


    func getCalendarEventsForCourses(courses: [Course]) async {

        let gtScheduler = GTSchedulerParser.shared
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)

        var allEventGroups: [CanvasCalendarEventGroup] = []

        for course in courses {
            
            let courseSchedule = try? await gtScheduler.getCanvasCourseScheduleMeetings(course: course) // TODO: ERROR HANDLING
            guard let courseSchedule = courseSchedule else { continue }

            // Dictionary to collect CanvasCalendarEvents grouped by date
            var eventsByDate: [Date: [CanvasCalendarEvent]] = [:]

            // Just make calendar events for one week (since that's all that can be displayed)
            for dayOffset in 0..<7 {
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
        calendarEventsFromCourseSchedule = allEventGroups
    }

    func incrementWeek() {

        if let newDate = Calendar.current.date(byAdding: .day, value: stepperIncrementCount, to: currentDate) {
            currentDate = newDate
        }
    }

    func decrementWeek() {
        if let newDate = Calendar.current.date(byAdding: .day, value: -stepperIncrementCount, to: currentDate) {
            currentDate = newDate
        }
    }

    func setToNow() {
        currentDate = .now
    }
}

