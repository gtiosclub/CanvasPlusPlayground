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
            #if os(iOS)
            Section {
                SidebarHeader()
                    .listRowInsets(EdgeInsets(top: 0, leading: 4.0, bottom: 0, trailing: 8.0))
                    .listRowBackground(Color.clear)
            }
            #endif

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
        .navigationSplitViewColumnWidth(min: 275, ideal: 275)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if let currentUser = profileManager.currentUser {
                    Button {
                        navigationModel.showProfileSheet.toggle()
                    } label: {
                        ProfilePicture(user: currentUser, size: 20)
                    }
                }
            }
        }
        #else
        .toolbar {
            ToolbarItem(placement: .principal) {
                Rectangle()
                    .fill(.clear)
            }
        }
        .contentMargins(.top, 0)
        .listSectionSpacing(16)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#if os(iOS)
private struct SidebarHeader: View {
    @Environment(ProfileManager.self) private var profileManager
    @Environment(NavigationModel.self) private var navigationModel

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(formattedDate)
                .font(.body.bold())
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            HStack(alignment: .top) {
                Text("Home")
                    .font(.largeTitle.bold())
                Spacer()

                if let currentUser = profileManager.currentUser {
                    Button {
                        navigationModel.showProfileSheet.toggle()
                    } label: {
                        ProfilePicture(user: currentUser, size: 42)
                    }
                }
            }
        }
    }
}
#endif

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
