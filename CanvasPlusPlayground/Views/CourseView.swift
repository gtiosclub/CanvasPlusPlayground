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
                EmptyView()
            } label: {
                Label("Tabs", systemImage: "tray.2")
            }
        }
        .navigationTitle(course.name ?? "Unknown Course")
    }
}
