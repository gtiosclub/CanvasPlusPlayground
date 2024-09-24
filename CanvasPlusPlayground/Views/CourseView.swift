//
//  CourseView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/8/24.
//

import SwiftUI

struct CourseView: View {
    let course: Course
    
    var body: some View {
        List {
            NavigationLink {
                CourseFilesView(course: course)
            } label: {
                Label("Files", systemImage: "folder")
            }
            
            NavigationLink {
                CourseAssignmentsView(course: course)
            } label: {
                Label("Assignments", systemImage: "circle.inset.filled")
            }
            NavigationLink {
                CalendarView(course: course)
            } label: {
                Label("Calendar", systemImage: "calendar")
            }
            NavigationLink {
                CourseTabsView(course: course)
            } label: {
                Label("Tabs", systemImage: "tray.2")
            }
            NavigationLink {
                CourseAnnouncementsView(course:course)
            } label: {
                Label("Announcements", systemImage: "bubble")
            }
            NavigationLink {
                CourseGradeView(course: course)
            } label: {
                Label("Grades", systemImage: "graduationcap.fill")
            }
        }
        .navigationTitle(course.name ?? "Unknown Course")
    }
}
