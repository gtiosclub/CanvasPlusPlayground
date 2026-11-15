import SwiftUI

struct CourseModulesPreview: View {
    @Environment(NavigationModel.self) private var navigationModel
    let course: Course
    @State private var manager: ModulesViewModel

    init(course: Course) {
        self.course = course
        _manager = State(initialValue: ModulesViewModel(courseID: course.id))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let block = CoursePreviewSelection.currentModule(manager.moduleBlocks) {
                Text(block.module.name)
                    .font(.callout.weight(.semibold))
                    .lineLimit(2)
                let items = CoursePreviewSelection.moduleItems(block)
                if items.isEmpty {
                    Text("\(block.module.itemsCount) items")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                ForEach(items) { item in
                    Button {
                        navigationModel.push(.coursePage(.modules, course))
                    } label: {
                        Text(item.title)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("No modules").foregroundStyle(.secondary)
            }
        }
        .task { await manager.fetchModules() }
        .onChange(of: course.id) {
            manager = ModulesViewModel(courseID: course.id)
            Task { await manager.fetchModules() }
        }
    }
}
