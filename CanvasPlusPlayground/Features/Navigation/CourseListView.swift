//
//  CourseListView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/15/25.
//

import SwiftUI

/// List of active courses. Used on compact size classes.
struct CourseListView: View {
    @Environment(NavigationModel.self) var navigationModel
    @Environment(CourseManager.self) var courseManager

    var body: some View {
        @Bindable var navigationModel = navigationModel

        NavigationStack(path: $navigationModel.allCoursesPath) {
            List {
                Section("Favorites") {
                    ForEach(courseManager.favoritedCourses) { course in
                        NavigationLink(value: NavigationModel.Destination.course(course)) {
                            CourseListCell(course: course)
                        }
                        .listItemTint(.fixed(course.rgbColors?.color ?? .accentColor))
                    }
                }

                Section("Other") {
                    ForEach(courseManager.unfavoritedCourses) { course in
                        NavigationLink(value: NavigationModel.Destination.course(course)) {
                            CourseListCell(course: course)
                        }
                        .listItemTint(.fixed(course.rgbColors?.color ?? .accentColor))
                    }
                }
            }
            .navigationTitle("Courses")
            .defaultNavigationDestination()
        }
    }
}
