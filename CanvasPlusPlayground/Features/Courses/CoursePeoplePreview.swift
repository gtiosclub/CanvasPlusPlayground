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
        .task { try? await manager.fetchPeople() }
        .onChange(of: course.id) {
            manager = PeopleManager(courseID: course.id)
            Task { try? await manager.fetchPeople() }
        }
    }
}
