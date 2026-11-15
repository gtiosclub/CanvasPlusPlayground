import SwiftUI

struct CourseFilesPreview: View {
    @Environment(NavigationModel.self) private var navigationModel
    let course: Course
    @State private var manager: CourseFileViewModel

    init(course: Course) {
        self.course = course
        _manager = State(initialValue: CourseFileViewModel(courseID: course.id))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let files = CoursePreviewSelection.files(manager.files)
            if files.isEmpty {
                Text("No files in the root folder").foregroundStyle(.secondary)
            }
            ForEach(files) { file in
                Button {
                    navigationModel.push(.file(file, course.id))
                } label: {
                    Text(file.displayName)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        .task { _ = await manager.fetchRoot() }
        .onChange(of: course.id) {
            manager = CourseFileViewModel(courseID: course.id)
            Task { _ = await manager.fetchRoot() }
        }
    }
}
