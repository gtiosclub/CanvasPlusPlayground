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
        Group {
            if isLoading == false && courseGroupsVM.groups.isEmpty {
                ContentUnavailableView("No groups for this course could be found.", systemImage: "person.2.slash.fill")
            } else {
                GroupsListView()
                    .searchable(
                        text: $courseGroupsVM.searchText,
                        prompt: "Search Groups..."
                    )
            }
        }

        .task {
            isLoading = true
            await courseGroupsVM.fetchGroups(for: course.id)
            isLoading = false
        }
        .statusToolbarItem("Groups", isVisible: isLoading)
        .environment(courseGroupsVM)
    }
}
