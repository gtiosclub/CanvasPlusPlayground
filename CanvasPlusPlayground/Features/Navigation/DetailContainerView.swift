//
//  DetailContainerView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 4/13/26.
//



import SwiftUI

struct DetailContainerView: View {
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(CourseManager.self) private var courseManager

    var body: some View {
        @Bindable var navigationModel = navigationModel

        switch navigationModel.selectedTab {
        case .dashboard:
            NavigationStack(path: $navigationModel.dashboardPath) {
                DashboardView()
                    .defaultNavigationDestination()
            }
        case let .course(courseID):
            if let course = courseManager.course(withID: courseID) {
                NavigationStack(path: $navigationModel.coursePath) {
                    CourseOverviewView(course: course)
                        .defaultNavigationDestination()
                }
            } else {
                ContentUnavailableView("Course unavailable", systemImage: "folder")
            }
        case let .coursePage(courseID, page):
            if let course = courseManager.course(withID: courseID) {
                NavigationStack(path: $navigationModel.coursePath) {
                    CourseDetailView(course: course, coursePage: page)
                        .defaultNavigationDestination()
                }
            } else {
                ContentUnavailableView("Course unavailable", systemImage: "folder")
            }
        case .allCourses:
            NavigationStack(path: $navigationModel.allCoursesPath) {
                CourseListView()
                    .defaultNavigationDestination()
            }
        case .search:
            ContentUnavailableView("Search", systemImage: "magnifyingglass")
        }
    }
}
