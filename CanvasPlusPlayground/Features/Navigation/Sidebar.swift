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

    @State private var isHiddenSectionExpanded: Bool = false

    var body: some View {
        @Bindable var navigationModel = navigationModel

        List(selection: $navigationModel.selectedNavigationPage) {
            Section {
                SidebarTiles()
            }

            Section("Favorites") {
                ForEach(courseManager.userFavCourses) { course in
                    NavigationLink(
                        value: NavigationPage.course(id: course.id)
                    ) {
                        CourseListCell(course: course)
                    }
                    .listItemTint(.fixed(course.rgbColors?.color ?? .accentColor))
                }
            }

            Section("My Courses") {
                ForEach(courseManager.userOtherCourses) { course in
                    NavigationLink(value: NavigationPage.course(id: course.id)) {
                        CourseListCell(course: course)
                    }
                    .listItemTint(.fixed(course.rgbColors?.color ?? .accentColor))
                }
            }

            if !courseManager.userHiddenCourses.isEmpty {
                Section("Hidden", isExpanded: $isHiddenSectionExpanded) {
                    ForEach(courseManager.userHiddenCourses) { course in
                        NavigationLink(value: NavigationPage.course(id: course.id)) {
                            CourseListCell(course: course)
                        }
                        .listItemTint(.fixed(course.rgbColors?.color ?? .accentColor))
                    }
                }
            }
        }
        .navigationTitle("Home")
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 285, ideal: 285, max: 350)
        #else
        .navigationSplitViewColumnWidth(min: 350, ideal: 350)
        #endif
        .listStyle(.sidebar)
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Settings", systemImage: "gear") {
                    navigationModel.showSettingsSheet.toggle()
                }
            }
        }
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if let currentUser = profileManager.currentUser {
                    Button {
                        navigationModel.showProfileSheet.toggle()
                    } label: {
                        #if os(macOS)
                        ProfilePicture(user: currentUser, size: 19)
                        #else
                        ProfilePicture(user: currentUser, size: 24)
                        #endif
                    }
                }
            }
        }
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
