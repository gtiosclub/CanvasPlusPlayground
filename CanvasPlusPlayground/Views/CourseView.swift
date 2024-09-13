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
                CourseAnnouncementsView(course:course)
            } label: {
                Label("Announcements", systemImage: "rectangle.3.group.bubble")
            }
        }
        .navigationTitle(course.name ?? "Unknown Course")
    }
}
