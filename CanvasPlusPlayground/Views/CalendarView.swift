//
//  CalendarView.swift
//  CanvasPlusPlayground
//
//  Created by Jiyoon Lee on 9/14/24.
//

import SwiftUI

struct CalendarView: View {
//    @Environment(CalendarManager.self) var calendarManager
//    @State private var showSheet: Bool = false
//
//    var body: some View {
//        @Bindable var calendarManager = calendarManager
//        NavigationStack {
//            List(calendarManager.calendar, id: \.id) { event in
//                VStack(alignment: .leading) {
//                    Text(event.title)
//                }
//            }
//            .navigationTitle("Calendar Events")
//            .refreshable {
//                await calendarManager.fetchCalendar()
//            }
//            .fullScreenCover(isPresented: $showSheet) {
//                NavigationStack {
//                    SetupView()
//                }
//                .onDisappear {
//                    Task {
//                        await calendarManager.fetchCalendar()
//                    }
//                }
//            }
//        }
//        .task {
//            if StorageKeys.needsAuthorization {
//                showSheet = true
//            } else {
//                await calendarManager.fetchCalendar()
//            }
//        }
//    }
//    let course: Course
//    @State var courseManager: CourseManager
//    init(course: Course) {
//        self.course = course
//        _courseManager = .init(initialValue: CourseManager())
//    }
//    var body: some View {
//        List(courseManager.courses, id: \.id) { course in
//            if let icsURL = course.calendar?.ics {
//                Text(icsURL)
//            } else {
//                Text("No calendar available")
//            }
//        }
//        .task {
//            await courseManager.getCourses()
//        }
//        .navigationTitle(course.name ?? "")
//    }
    
    let course: Course
    @State var courseManager: CourseManager

    init(course: Course) {
        self.course = course
        _courseManager = .init(initialValue: CourseManager())
    }

    var body: some View {
        List(courseManager.courses, id: \.id) { course in
            if let icsURL = course.calendar?.ics, let url = URL(string: icsURL) {
                Link("Open in Calendar", destination: url)
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
