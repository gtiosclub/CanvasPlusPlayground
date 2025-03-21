//
//  CourseView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/8/24.
//

import SwiftUI

struct CourseView: View {
    @Environment(PickerService.self) private var pickerService: PickerService?
    @Environment(NavigationModel.self) private var navigationModel
    let course: Course

    private var coursePages: [NavigationModel.CoursePage] {
        pickerService?.supportedPickerViews ?? NavigationModel.CoursePage.allCases
    }

    var body: some View {
        @Bindable var navigationModel = navigationModel

        List(coursePages, id: \.self, selection: $navigationModel.selectedCoursePage) { page in
            NavigationLink(value: page) {
                Label(page.title, systemImage: page.systemImageIcon)
            }
        }
        .tint(course.rgbColors?.color)
        .navigationTitle(course.displayName)
        #if os(iOS)
        .listStyle(.insetGrouped)
        .navigationDestination(item: $navigationModel.selectedCoursePage) { coursePage in
            CourseDetailView(
                course: course,
                coursePage: coursePage
            )
        }
        #else
        .listStyle(.sidebar)
        .navigationDestination(for: NavigationModel.CoursePage.self) { coursePage in
            CourseDetailView(
                course: course,
                coursePage: coursePage
            )
        }
        #endif
    }
}
