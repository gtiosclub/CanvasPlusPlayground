//
//  GroupsView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 3/23/25.
//

import SwiftUI

struct CourseGroupsView: View {
    let course: Course

    @State private var courseGroupsVM: CourseGroupsViewModel
    @State private var isLoading: Bool = false

    init(course: Course) {
        self.course = course
        self._courseGroupsVM = State(initialValue: CourseGroupsViewModel())
    }

    var body: some View {
        GroupsListView()
            .task {
                isLoading = true
                await courseGroupsVM.fetchGroups(for: course.id)
                isLoading = false
            }
            .statusToolbarItem("Groups", isVisible: isLoading)
            .environment(courseGroupsVM)
            #if os(iOS)
            .searchable(
                text: $courseGroupsVM.searchText,
                placement:
                        .navigationBarDrawer(
                            displayMode: .always
                        ),
                prompt: "Search Groups..."
            )
            #else
            .searchable(
                text: $courseGroupsVM.searchText,
                prompt: "Search Groups..."
            )
            #endif
    }
}
