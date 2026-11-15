import SwiftUI

struct CoursePeoplePreview: View {
    @Environment(NavigationModel.self) private var navigationModel
    let course: Course
    @State private var manager: PeopleManager
    @State private var managerCourseID: String

    init(course: Course) {
        self.course = course
        _manager = State(initialValue: PeopleManager(courseID: course.id))
        _managerCourseID = State(initialValue: course.id)
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
        // Keyed by course so SwiftUI cancels the page loop on collapse and on a course switch.
        .task(id: course.id) {
            if managerCourseID != course.id {
                manager = PeopleManager(courseID: course.id)
                managerCourseID = course.id
            }
            await loadPeople(manager)
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

    /// - Parameters:
    ///   - maxPages: The most pages to request, so a very large course cannot issue unbounded requests.
    ///   - fetchNext: Loads one page and returns whether another page is available.
    /// - Throws: Cancellation or the first page-fetch failure; neither is retried.
    @MainActor
    static func loadPages(maxPages: Int = 20, fetchNext: () async throws -> Bool) async throws {
        // shortcut: 20 pages of 60 covers 1,200 people; ask Canvas for teacher/TA roles directly if bigger courses miss instructors.
        for _ in 0..<maxPages {
            try Task.checkCancellation()
            if try await !fetchNext() { return }
        }
    }
}
