//
//  CombinedCalendar.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/25/25.
//

import SwiftUI

struct CombinedCalendar: View {
    @Environment(CourseManager.self) var courseManager
    @State var calendarManager: CombinedCalendarManager = CombinedCalendarManager()

    var body: some View {
        CalendarEventsView(events: calendarManager.calendarEvents)
            .task {
                await calendarManager.getCalendarEventsForCourses(courses: courseManager.activeCourses)
            }
    }
}

