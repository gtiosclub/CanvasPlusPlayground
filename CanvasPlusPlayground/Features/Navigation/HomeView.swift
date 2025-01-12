//
//  ContentView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI

struct HomeView: View {
    typealias NavigationPage = NavigationModel.NavigationPage

    @Environment(ProfileManager.self) var profileManager
    @Environment(CourseManager.self) var courseManager
    @Environment(NavigationModel.self) var navigationModel

    @EnvironmentObject private var intelligenceManager: IntelligenceManager
    @EnvironmentObject private var llmEvaluator: LLMEvaluator

    @State private var columnVisibility = NavigationSplitViewVisibility.all

    @SceneStorage("CourseListView.selectedNavigationPage")
    private var selectedNavigationPage: NavigationPage?

    @SceneStorage("CourseListView.selectedCoursePage")
    private var selectedCoursePage: NavigationModel.CoursePage?

    private var selectedCourse: Course? {
        guard let selectedNavigationPage, case .course(let id) = selectedNavigationPage else {
            return nil
        }

        return courseManager.courses.first(where: { $0.id == id })
    }

    var body: some View {
        @Bindable var courseManager = courseManager
        @Bindable var navigationModel = navigationModel

        NavigationSplitView(columnVisibility: $columnVisibility) {
            Sidebar()
        } content: {
            contentView
        } detail: {
            if let selectedCourse, let selectedCoursePage {
                CourseDetailView(
                    course: selectedCourse,
                    coursePage: selectedCoursePage
                )
            }
        }
        .task {
            navigationModel.selectedNavigationPage = selectedNavigationPage
            navigationModel.selectedCoursePage = selectedCoursePage
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
        #if os(iOS)
        .sheet(isPresented: $navigationModel.showSettingsSheet) {
            SettingsView()
        }
        #endif
        .environment(navigationModel)
    }

    @ViewBuilder
    private var contentView: some View {
        if let selectedCourse {
            CourseView(course: selectedCourse)
        } else if let selectedNavigationPage {
            switch selectedNavigationPage {
            case .announcements: Text("All Announcements")
            case .toDoList: AggregatedAssignmentsView()
            case .pinned: PinnedItemsView()
            default: EmptyView()
            }
        } else {
            ContentUnavailableView("Select a course", systemImage: "folder")
        }
    }
}

#Preview {
    HomeView()
        .environment(CourseManager())
        .environment(ProfileManager())
        .environmentObject(LLMEvaluator())
        .environmentObject(IntelligenceManager())
}
