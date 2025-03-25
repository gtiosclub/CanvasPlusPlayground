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
        self._courseGroupsVM = State(initialValue: CourseGroupsViewModel(courseId: self.course.id))
    }

    var body: some View {
        GroupsListView(groups: courseGroupsVM.groups)
            .task {
                isLoading = true
                await courseGroupsVM.fetchGroups()
                isLoading = false
            }
            .statusToolbarItem("Groups", isVisible: isLoading)
    }
}
