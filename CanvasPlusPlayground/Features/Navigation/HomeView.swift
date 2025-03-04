//
//  ContentView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI

struct HomeView: View {
    typealias NavigationPage = NavigationModel.NavigationPage

    @Environment(ProfileManager.self) private var profileManager
    @Environment(CourseManager.self) private var courseManager
    @Environment(NavigationModel.self) private var navigationModel

    @EnvironmentObject private var intelligenceManager: IntelligenceManager
    @EnvironmentObject private var llmEvaluator: LLMEvaluator

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

        return courseManager.allCourses.first(where: { $0.id == id })
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
            #if os(macOS)
                .overlay(alignment: .bottomLeading) {
                    toast
                }
            #endif
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
        .animation(.spring, value: navigationModel.toast)
        #if os(iOS)
        .sheet(isPresented: $navigationModel.showSettingsSheet) {
            SettingsView()
        }
        .overlay(alignment: .bottom) {
            toast
                .animation(.spring, value: navigationModel.toast)
        }
        #endif
        .environment(navigationModel)
    }

    @ViewBuilder
    private var toast: some View {
        if let toast = navigationModel.toast {
            ToastView(toast: toast)
                .transition(.blur
                    .combined(with: .scale(scale: 0.9))
                    .combined(with: .offset(x: 0, y: 10))
                    .combined(with: .opacity))
                .padding()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if let selectedCourse {
            CourseView(course: selectedCourse)
        } else if let selectedNavigationPage {
            switch selectedNavigationPage {
            case .announcements:
                AllAnnouncementsView()
            case .toDoList:
                AggregatedAssignmentsView()
            case .pinned:
                PinnedItemsView()
            default:
                EmptyView()
            }
        } else {
            ContentUnavailableView("Select a course", systemImage: "folder")
        }
    }

    private func loadCourses() async {
        isLoadingCourses = true
        await courseManager.getCourses()
        await profileManager.getCurrentUserAndProfile()
        isLoadingCourses = false
    }
}

struct BlurAnimationModifier: AnimatableModifier {
    var blur: Double

    var animatableData: Double {
        get { blur }
        set { blur = newValue }
    }

    func body(content: Content) -> some View {
        content
            .blur(radius: self.animatableData)
    }
}

extension AnyTransition {
    static var blur: AnyTransition {
        AnyTransition.modifier(
            active: BlurAnimationModifier(blur: 5.0),
            identity: BlurAnimationModifier(blur: 0.0)
        )
    }
}

#Preview {
    HomeView()
        .environment(CourseManager())
        .environment(ProfileManager())
        .environmentObject(LLMEvaluator())
        .environmentObject(IntelligenceManager())
}
