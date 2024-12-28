//
//  Sidebar.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/28/24.
//

import SwiftUI

struct Sidebar: View {
    typealias NavigationPage = NavigationModel.NavigationPage

    @Environment(NavigationModel.self) private var navigationModel
    @Environment(CourseManager.self) private var courseManager
    @Environment(ProfileManager.self) private var profileManager

    @State private var isLoadingCourses = false

    var body: some View {
        @Bindable var navigationModel = navigationModel

        List(selection: $navigationModel.selectedNavigationPage) {
            Section {
                SidebarTiles()
            }

            Section("Favorites") {
                ForEach(courseManager.userFavCourses, id: \.id) { course in
                    NavigationLink(
                        value: NavigationPage.course(id: course.id)
                    ) {
                        CourseListCell(course: course)
                    }
                    .tint(course.rgbColors?.color)
                }
            }

            Section("Courses") {
                ForEach(courseManager.userOtherCourses, id: \.id) { course in
                    NavigationLink(value: NavigationPage.course(id: course.id)) {
                        CourseListCell(course: course)
                    }
                    .tint(course.rgbColors?.color)
                }
            }
        }
        .navigationTitle("Home")
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 275, ideal: 275)
        #endif
        .listStyle(.sidebar)
        .statusToolbarItem("Courses", isVisible: isLoadingCourses)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Settings", systemImage: "gear") {
                    navigationModel.showSettingsSheet.toggle()
                }
            }
        }
        .task {
            if StorageKeys.needsAuthorization {
                navigationModel.showAuthorizationSheet = true
            } else {
                await loadCourses()
            }
        }
        .refreshable {
            await loadCourses()
        }
    }

    private func loadCourses() async {
        isLoadingCourses = true
        await courseManager.getCourses()
        await profileManager.getCurrentUserAndProfile()
        isLoadingCourses = false
    }
}

private struct SidebarTiles: View {
    @Environment(NavigationModel.self) private var navigationModel

    var body: some View {
        #if os(macOS)
        let columns = Array(
            repeating: GridItem(.adaptive(minimum: 90)),
            count: 2
        )
        #else
        let columns = Array(
            repeating: GridItem(.adaptive(minimum: 150)),
            count: 2
        )
        #endif

        return LazyVGrid(
            columns: columns,
            spacing: 4
        ) {
            SidebarTile(
                "Announcements",
                systemIcon: "bell.circle.fill",
                color: .blue,
                page: .announcements
            ) {
                navigationModel.selectedNavigationPage = .announcements
            }

            SidebarTile(
                "To-Do",
                systemIcon: "list.bullet.circle.fill",
                color: .red,
                page: .toDoList
            ) {
                navigationModel.selectedNavigationPage = .toDoList
            }

            SidebarTile(
                "Pinned",
                systemIcon: "pin.circle.fill",
                color: .orange,
                page: .pinned
            ) {
                navigationModel.selectedNavigationPage = .pinned
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .buttonStyle(.plain)
    }
}
