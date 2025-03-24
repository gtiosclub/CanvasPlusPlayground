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

    init(course: Course) {
        self.course = course
        self._courseGroupsVM = State(initialValue: CourseGroupsViewModel(courseId: self.course.id))
    }

    var body: some View {
            GroupsListView(groups: courseGroupsVM.displayedGroups)

        .task {
            await courseGroupsVM.fetchGroups()
        }
    }
}

#Preview {
    CourseGroupsView(course: .sample)
}
