//
//  CourseView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/8/24.
//

import SwiftUI

struct CourseView: View {
    @Environment(NavigationModel.self) private var navigationModel
    let course: Course
    
    var body: some View {
        @Bindable var navigationModel = navigationModel

        List(selection: $navigationModel.selectedCoursePage) {
            NavigationLink(value: NavigationModel.CoursePage.files) {
                Label("Files", systemImage: "folder")
            }

            NavigationLink(value: NavigationModel.CoursePage.assignments) {
                Label("Assignments", systemImage: "circle.inset.filled")
            }

            NavigationLink(value: NavigationModel.CoursePage.calendar) {
                Label("Calendar", systemImage: "calendar")
            }

            NavigationLink(value: NavigationModel.CoursePage.tabs) {
                Label("Tabs", systemImage: "tray.2")
            }

            NavigationLink(value: NavigationModel.CoursePage.announcements) {
                Label("Announcements", systemImage: "bubble")
            }

            NavigationLink(value: NavigationModel.CoursePage.grades) {
                Label("Grades", systemImage: "graduationcap.fill")
            }

            NavigationLink(value: NavigationModel.CoursePage.people) {
                Label("People", systemImage: "person.crop.circle.fill")
            }
        }
        .tint(course.rgbColors?.color)
        .navigationTitle(course.displayName)
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.sidebar)
    }
}
