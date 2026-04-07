//
//  ContentView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI
import CoreSpotlight
import SwiftData

struct HomeView: View {
    @Environment(ToDoListManager.self) private var toDoListManager
    @Environment(ProfileManager.self) private var profileManager
    @Environment(CourseManager.self) private var courseManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var isLoadingCourses = false
    @State private var navigationModel = NavigationModel()
    @State private var pendingSpotlightIdentifier: String?

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
//                #if os(macOS)
//                .frame(width: 560)
//                .frame(minHeight: 100, maxHeight: 480)
//                #endif
        }
        .background {
            Button("") {
                navigationModel.showSpotlightSearch = true
            }
            .keyboardShortcut("k", modifiers: .command)
            .hidden()
        }
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
                return
            }
            if !handleSpotlightDeepLink(identifier) {
                pendingSpotlightIdentifier = identifier
            }
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
    private func destinationForDeepLink(type: String, id: String) -> NavigationModel.Destination? {
        let context = ModelContext.shared

        switch type {
        case "course":
            guard let course = courseManager.course(withID: id) else { return nil }
            return .course(course)

        case "assignment":
            let predicate = #Predicate<Assignment> { $0.id == id }
            guard let assignment = try? context.fetch(
                FetchDescriptor(predicate: predicate)
            ).first else { return nil }
            return .assignment(assignment)

        case "announcement":
            let predicate = #Predicate<DiscussionTopic> { $0.id == id }
            guard let topic = try? context.fetch(
                FetchDescriptor(predicate: predicate)
            ).first else { return nil }
            return .announcement(topic)

        case "quiz":
            let predicate = #Predicate<Quiz> { $0.id == id }
            guard let quiz = try? context.fetch(
                FetchDescriptor(predicate: predicate)
            ).first else { return nil }
            return .quiz(quiz)

        case "page":
            let predicate = #Predicate<Page> { $0.id == id }
            guard let page = try? context.fetch(
                FetchDescriptor(predicate: predicate)
            ).first else { return nil }
            return .page(page)

        case "file":
            let predicate = #Predicate<File> { $0.id == id }
            guard let file = try? context.fetch(
                FetchDescriptor(predicate: predicate)
            ).first else { return nil }
            guard let folderId = file.folderId else { return nil }
            return .file(file, String(folderId))

        case "module":
            let predicate = #Predicate<Module> { $0.id == id }
            guard let module = try? context.fetch(
                FetchDescriptor(predicate: predicate)
            ).first,
                  let courseID = module.courseID,
                  let course = courseManager.course(withID: courseID) else { return nil }
            return .coursePage(.modules, course)

        case "person":
            let predicate = #Predicate<User> { $0.id == id }
            guard let user = try? context.fetch(
                FetchDescriptor(predicate: predicate)
            ).first,
                  let courseID = user.courseId,
                  let course = courseManager.course(withID: courseID) else { return nil }
            return .coursePage(.people, course)

        case "group":
            let predicate = #Predicate<CanvasGroup> { $0.id == id }
            guard let group = try? context.fetch(
                FetchDescriptor(predicate: predicate)
            ).first,
                  let courseId = group.courseId,
                  let course = courseManager.course(withID: String(courseId)) else { return nil }
            return .coursePage(.groups, course)

        case "todo":
            return .allToDos

        default:
            return nil
        }
    }

    
    @discardableResult
    private func handleSpotlightDeepLink(_ identifier: String) -> Bool {
        let parts = identifier.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else { return false }

        let type = String(parts[0])
        let id = String(parts[1])

        guard let destination = destinationForDeepLink(type: type, id: id) else { return false }

        navigationModel.selectedTab = .dashboard
        DispatchQueue.main.async {
            navigationModel.dashboardPath.append(destination)
        }
        return true
    }

    private func drainPendingSpotlightDeepLink() {
        guard let pending = pendingSpotlightIdentifier else { return }
        if handleSpotlightDeepLink(pending) {
            pendingSpotlightIdentifier = nil
        }
    }



}

#Preview {
    HomeView()
        .environment(CourseManager())
        .environment(ProfileManager())
}
