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
    @Environment(TodayWidgetManager.self) private var todayWidgetManager
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
            TabSection("Courses") {
                ForEach(courseManager.activeCourses) { course in
                    Tab(value: NavigationModel.Tab.course(course.id)) {
                        NavigationStack(path: $navigationModel.coursePath) {
                            CourseView(course: course)
                        }
                    } label: {
                        CourseListCell(course: course)
                    }
                }
            }
            .hidden(horizontalSizeClass == .compact)

            Tab("Courses", systemImage: "book.pages.fill", value: .allCourses) {
                coursesTabView
            }
            .hidden(horizontalSizeClass == .regular)
        }
        .tabViewStyle(.sidebarAdaptable)
        .task {
            if !StorageKeys.hasCompletedOnboarding {
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

        async let coursesTask: Void = courseManager.getCourses()
        async let profileTask: Void = profileManager.getCurrentUserAndProfile()
        async let todoTask: Void = toDoListManager.fetchToDoItemCount()

        
        await (_, _, _) = (coursesTask, profileTask, todoTask)

        isLoadingCourses = false
    }

    @ViewBuilder
    private var coursesTabView: some View {
        NavigationStack(path: $navigationModel.allCoursesPath) {
            List(courseManager.activeCourses) { course in
                NavigationLink(value: NavigationModel.Destination.course(course)) {
                    CourseListCell(course: course)
                }
                .listItemTint(.fixed(course.rgbColors?.color ?? .accentColor))
            }
            .navigationTitle("Courses")
            .navigationDestination(for: NavigationModel.Destination.self) { destination in
                destination.destinationView()
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(CourseManager())
        .environment(ProfileManager())
}
