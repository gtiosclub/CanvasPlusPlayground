import SwiftUI

struct CoursePagesPreview: View {
    @Environment(NavigationModel.self) private var navigationModel
    let course: Course
    @State private var manager: PagesManager

    init(course: Course) {
        self.course = course
        _manager = State(initialValue: PagesManager(courseID: course.id))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let pages = CoursePreviewSelection.pages(manager.pages)
            if pages.isEmpty {
                Text("No pages").foregroundStyle(.secondary)
            }
            ForEach(pages) { page in
                Button {
                    navigationModel.push(.page(page))
                } label: {
                    Text(page.title ?? "Untitled page")
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        .task { await manager.fetchPages() }
        .onChange(of: course.id) {
            manager = PagesManager(courseID: course.id)
            Task { await manager.fetchPages() }
        }
    }
}
