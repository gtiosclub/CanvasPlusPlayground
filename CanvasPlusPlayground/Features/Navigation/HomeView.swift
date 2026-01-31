//
//  ContentView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI

struct HomeView: View {
    @Environment(ToDoListManager.self) private var toDoListManager
    @Environment(ProfileManager.self) private var profileManager
    @Environment(CourseManager.self) private var courseManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var isLoadingCourses = false
    @State private var navigationModel = NavigationModel()

    var body: some View {
        @Bindable var courseManager = courseManager
        @Bindable var navigationModel = navigationModel

        TabView(selection: $navigationModel.selectedTab) {
            // dashboard
            Tab("Dashboard", systemImage: "rectangle.grid.2x2.fill", value: .dashboard) {
                NavigationStack(path: $navigationModel.dashboardPath) {
                    DashboardView()
                }
            }

            // course/courses
            TabSection("Favorited Courses") {
                ForEach(courseManager.favoritedCourses) { course in
                    Tab(value: NavigationModel.Tab.course(course.id)) {
                        NavigationStack(path: $navigationModel.coursePath) {
                            CourseView(course: course)
                                .defaultNavigationDestination()
                        }
                    } label: {
                        CourseListCell(course: course)
                    }
                }
            }
            .tabPlacement(.sidebarOnly)
            .hidden(horizontalSizeClass == .compact)

            TabSection("Other Courses") {
                ForEach(courseManager.unfavoritedCourses) { course in
                    Tab(value: NavigationModel.Tab.course(course.id)) {
                        NavigationStack(path: $navigationModel.coursePath) {
                            CourseView(course: course)
                                .defaultNavigationDestination()
                        }
                    } label: {
                        CourseListCell(course: course)
                    }
                }
            }
            .tabPlacement(.sidebarOnly)
            .hidden(horizontalSizeClass == .compact)

            Tab("Courses", systemImage: "book.pages.fill", value: .allCourses) {
                CourseListView()
            }
            .hidden(horizontalSizeClass == .regular)
        }
        .tabViewStyle(.sidebarAdaptable)
        .task {
            if AppEnvironment.isSandbox {
                await loadCourses()
            } else if !StorageKeys.hasCompletedOnboarding {
                navigationModel.showAuthorizationSheet = true
            } else if StorageKeys.needsAuthorization {
                navigationModel.showAuthorizationSheet = true
            } else {
                await loadCourses()
            }
        }
        .sheet(isPresented: $navigationModel.showAuthorizationSheet) {
            Task {
                await loadCourses()
            }
        } content: {
            if !StorageKeys.hasCompletedOnboarding {
                OnboardingFlowView()
            } else {
                NavigationStack {
                    SetupView()
                }
                .interactiveDismissDisabled()
            }
        }
        .sheet(isPresented: $navigationModel.showProfileSheet) {
            if let currentUser = profileManager.currentUser {
                NavigationStack {
                    ProfileView(
                        user: currentUser,
                        showCommonCourses: false
                    )
                }
            }
        }
        #if os(iOS)
        .sheet(isPresented: $navigationModel.showSettingsSheet) {
            SettingsView()
        }
        #endif
        .environment(navigationModel)
    }

    private func loadCourses() async {
        isLoadingCourses = true

        if AppEnvironment.isSandbox {
            await courseManager.getCoursesIfNeeded()
            await profileManager.getCurrentUserAndProfileIfNeeded()
            await toDoListManager.fetchToDoItemCountIfNeeded()
        } else {
            async let coursesTask: Void = courseManager.getCourses()
            async let profileTask: Void = profileManager.getCurrentUserAndProfile()
            async let todoTask: Void = toDoListManager.fetchToDoItemCount()

            await (_, _, _) = (coursesTask, profileTask, todoTask)
        }

        isLoadingCourses = false
    }
}

#Preview {
    HomeView()
        .environment(CourseManager())
        .environment(ProfileManager())
}
