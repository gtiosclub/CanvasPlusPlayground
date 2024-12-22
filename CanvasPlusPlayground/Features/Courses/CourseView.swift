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

        List(NavigationModel.CoursePage.allCases, id: \.self, selection: $navigationModel.selectedCoursePage) { page in
            NavigationLink(value: page) {
                Label(page.title, systemImage: page.systemImageIcon)
            }
        }
        .tint(course.rgbColors?.color)
        .navigationTitle(course.displayName)
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.sidebar)
        #endif
    }
}
