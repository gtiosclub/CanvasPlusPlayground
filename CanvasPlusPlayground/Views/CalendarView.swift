//
//  CalendarView.swift
//  CanvasPlusPlayground
//
//  Created by Jiyoon Lee on 9/16/24.
//

import SwiftUI

struct CalendarView: View {
    let course: Course
    @State var courseManager: CourseManager
    init(course: Course) {
        self.course = course
        _courseManager = .init(initialValue: CourseManager())
    }
    var body: some View {
        List(courseManager.courses, id: \.id) { course in
            if let icsURL = course.calendar?.ics {
                Text(icsURL)
            } else {
                Text("No calendar available")
            }
        }
        .task {
            await courseManager.getCourses()
        }
        .navigationTitle(course.name ?? "")
    }
}

