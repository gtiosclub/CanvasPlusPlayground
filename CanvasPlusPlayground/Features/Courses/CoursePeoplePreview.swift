import SwiftUI

struct CoursePeoplePreview: View {
    @Environment(NavigationModel.self) private var navigationModel
    let course: Course
    @State private var manager: PeopleManager

    init(course: Course) {
        self.course = course
        _manager = State(initialValue: PeopleManager(courseID: course.id))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let people = CoursePreviewSelection.people(manager.displayedUsers)
            if people.isEmpty {
                Text("No people").foregroundStyle(.secondary)
            }
            ForEach(people) { person in
                Button {
                    navigationModel.push(.coursePage(.people, course))
                } label: {
                    Text(person.name)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        .task { await loadPeople(manager) }
        .onChange(of: course.id) {
            manager = PeopleManager(courseID: course.id)
            let replacement = manager
            Task { await loadPeople(replacement) }
        }
    }

    private func loadPeople(_ manager: PeopleManager) async {
        do {
            try await Self.loadPages {
                let previousPage = manager.page
                try await manager.fetchPeople()
                return !AppEnvironment.isSandbox && manager.page > previousPage
            }
        } catch is CancellationError {
            return
        } catch {
            LoggerService.main.error("People preview fetch failed: \(error)")
        }
    }

    /// - Parameter fetchNext: Loads one page and returns whether another page is available.
    /// - Throws: Cancellation or the first page-fetch failure; neither is retried.
    @MainActor
    static func loadPages(fetchNext: () async throws -> Bool) async throws {
        while true {
            try Task.checkCancellation()
            if try await !fetchNext() { return }
        }
    }
}
