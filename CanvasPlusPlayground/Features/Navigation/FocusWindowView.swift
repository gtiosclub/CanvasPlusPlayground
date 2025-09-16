//
//  FocusWindowView.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 9/1/25.
//

import SwiftUI

struct FocusWindowView: View {

    @Environment(CourseManager.self) private var courseManager
    @State private var navigationModel = NavigationModel()

    let info: FocusWindowInfo

    private var coursePage: NavigationModel.CoursePage { info.coursePage }

    private var course: Course? { courseManager.activeCourses.first(where: { $0.id == info.courseID }) }

    var body: some View {

        @Bindable var navigationModel = navigationModel

        if let course {
            NavigationStack(path: $navigationModel.navigationPath) {
                CourseDetailView(course: course, coursePage: coursePage)
                    .defaultNavigationDestination(courseID: info.courseID)

            }
            .environment(navigationModel)
        } else {
            ContentUnavailableView("Unable to open new window", systemImage: "questionmark.square.dashed", description: Text("An error occurred while opening new window"))
                .task {
                    if courseManager.activeCourses.isEmpty { await courseManager.getCourses() }
                }
        }
    }
}


