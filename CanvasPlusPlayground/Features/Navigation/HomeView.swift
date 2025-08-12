//
//  ContentView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI

struct HomeView: View {
    typealias NavigationPage = NavigationModel.NavigationPage

    @Environment(ToDoListManager.self) private var toDoListManager
    @Environment(ProfileManager.self) private var profileManager
    @Environment(CourseManager.self) private var courseManager
    @Environment(NavigationModel.self) private var navigationModel

    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var isLoadingCourses = false

    @SceneStorage("CourseListView.selectedNavigationPage")
    private var selectedNavigationPage: NavigationPage?

    @SceneStorage("CourseListView.selectedCoursePage")
    private var selectedCoursePage: NavigationModel.CoursePage?

    private var selectedCourse: Course? {
        guard let selectedNavigationPage, case .course(let id) = selectedNavigationPage else {
            return nil
        }

        return courseManager.activeCourses.first(where: { $0.id == id })
    }

    var body: some View {
        @Bindable var courseManager = courseManager
        @Bindable var navigationModel = navigationModel

        NavigationSplitView(columnVisibility: $columnVisibility) {
            Sidebar()
                .statusToolbarItem("Courses", isVisible: isLoadingCourses)
                .refreshable {
                    await loadCourses()
                }
        } detail: {
            contentView
        }
        .task {
            navigationModel.selectedNavigationPage = selectedNavigationPage
            navigationModel.selectedCoursePage = selectedCoursePage
        }
        .task {
            if StorageKeys.needsAuthorization {
                navigationModel.showAuthorizationSheet = true
            } else {
                await loadCourses()
            }
        }
        .onChange(of: navigationModel.selectedNavigationPage) { _, new in
            selectedNavigationPage = new
        }
        .onChange(of: navigationModel.selectedCoursePage) { _, new in
            selectedCoursePage = new
        }
        .sheet(isPresented: $navigationModel.showAuthorizationSheet) {
            NavigationStack {
                SetupView()
            }
            .interactiveDismissDisabled()
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

    @ViewBuilder
    private var contentView: some View {
        @Bindable var navigationModel = navigationModel

        NavigationStack(path: $navigationModel.navigationPath) {
            if let selectedCourse {
                CourseView(course: selectedCourse)
            } else if let selectedNavigationPage {
                Group {
                    switch selectedNavigationPage {
                    case .announcements:
                        AllAnnouncementsView()
                    case .toDoList:
                        ToDoListView()
                    case .pinned:
                        PinnedItemsView()
                    default:
                        EmptyView()
                    }
                }
                .navigationDestination(for: NavigationModel.Destination.self) { destination in
                    destination.destinationView()
                }
            } else {
                ContentUnavailableView("Select a course", systemImage: "folder")
            }
        }
    }

    private func loadCourses() async {
        isLoadingCourses = true

        async let coursesTask: Void = courseManager.getCourses()
        async let profileTask: Void = profileManager.getCurrentUserAndProfile()
        async let todoTask: Void = toDoListManager.fetchToDoItemCount()

        await (_, _, _) = (coursesTask, profileTask, todoTask)

        isLoadingCourses = false
    }
}

#Preview {
    HomeView()
        .environment(CourseManager())
        .environment(ProfileManager())
}
