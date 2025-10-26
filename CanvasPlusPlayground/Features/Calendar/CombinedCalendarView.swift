//
//  CombinedCalendar.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/25/25.
//

import SwiftUI

struct CombinedCalendar: View {
    @Environment(CourseManager.self) var courseManager
    @Environment(CombinedCalendarManager.self) var calendarManager

    var body: some View {
        CalendarEventsView(events: calendarManager.calendarEvents)
            .task {
                // we only want to do this on first open
                if !calendarManager.hasPingedServer {
                    await calendarManager.getCalendarEventsForCourses(courses: courseManager.activeCourses)
                }
            }
    }
}

