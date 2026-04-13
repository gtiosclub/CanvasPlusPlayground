//
//  ContentView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(ToDoListManager.self) private var toDoListManager
    @Environment(ProfileManager.self) private var profileManager
    @Environment(CourseManager.self) var courseManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var isLoadingCourses = false
    @State var navigationModel = NavigationModel()
    @State var pendingSpotlightIdentifier: String?
    @State private var expandedCourses: Set<Course.ID> = []

    /// `List(selection:)` requires an optional binding, but `selectedTab` is non-optional.
    private var selectedTabBinding: Binding<NavigationModel.Tab?> {
        Binding(
            get: { navigationModel.selectedTab },
            set: { newValue in
                if let newValue {
                    navigationModel.selectedTab = newValue
                }
            }
        )
    }

    var body: some View {
        @Bindable var courseManager = courseManager
        @Bindable var navigationModel = navigationModel

        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                selectedTab: selectedTabBinding,
                expandedCourses: $expandedCourses
            )
        } detail: {
            DetailContainerView()
        }
        .task {
            if AppEnvironment.isSandbox {
                await loadCourses()
                SandboxDataLoader.persistSandboxData()
                await SpotlightIndexer.shared.indexAllContent()
                drainPendingSpotlightDeepLink()
            } else if !StorageKeys.hasCompletedOnboarding {
                navigationModel.showAuthorizationSheet = true
            } else if StorageKeys.needsAuthorization {
                navigationModel.showAuthorizationSheet = true
            } else {
                await loadCourses()
                await SpotlightIndexer.shared.indexAllContent()
                drainPendingSpotlightDeepLink()
            }
        }
        .sheet(isPresented: $navigationModel.showAuthorizationSheet) {
            Task {
                await loadCourses()
                drainPendingSpotlightDeepLink()
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
        .sheet(isPresented: $navigationModel.showSpotlightSearch) {
            SpotlightSearchView()
        }
        .background {
            Button("") {
                navigationModel.showSpotlightSearch = true
            }
            .keyboardShortcut("k", modifiers: .command)
            .hidden()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSpotlightDeepLink)) { notification in
            guard let identifier = notification.userInfo?[SpotlightDeepLinkUserInfoKey.identifier] as? String else {
                return
            }
            if !handleSpotlightDeepLink(identifier) {
                pendingSpotlightIdentifier = identifier
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSpotlightSearch)) { _ in
            navigationModel.showSpotlightSearch = true
        }
        .environment(navigationModel)
    }

    private func loadCourses() async {
        isLoadingCourses = true

        if AppEnvironment.isSandbox {
            await courseManager.getSandboxedCourses()
            await profileManager.getSandboxedCurrentUserAndProfile()
            await toDoListManager.fetchSandboxedToDoItemCount()
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
