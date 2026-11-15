import SwiftUI

struct CourseGroupsPreview: View {
    @Environment(NavigationModel.self) private var navigationModel
    let course: Course
    @State private var manager: CourseGroupsViewModel

    init(course: Course) {
        self.course = course
        _manager = State(initialValue: CourseGroupsViewModel())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let groups = CoursePreviewSelection.groups(manager.groupsDisplayed)
            if groups.isEmpty {
                Text("No groups").foregroundStyle(.secondary)
            }
            ForEach(groups) { group in
                Button {
                    navigationModel.push(.coursePage(.groups, course))
                } label: {
                    Text(group.name)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        .task { await manager.fetchGroups(for: course.id) }
        .onChange(of: course.id) {
            manager = CourseGroupsViewModel()
            Task { await manager.fetchGroups(for: course.id) }
        }
    }
}
