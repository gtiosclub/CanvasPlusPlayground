import SwiftUI

struct CourseQuizzesPreview: View {
    @Environment(NavigationModel.self) private var navigationModel
    let course: Course
    @State private var manager: QuizzesViewModel

    init(course: Course) {
        self.course = course
        _manager = State(initialValue: QuizzesViewModel(courseId: course.id))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let quizzes = CoursePreviewSelection.quizzes(Array(manager.quizzes))
            if quizzes.isEmpty {
                Text("No quizzes").foregroundStyle(.secondary)
            }
            ForEach(quizzes) { quiz in
                Button {
                    navigationModel.push(.quiz(quiz))
                } label: {
                    Text(quiz.title)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        .task { await manager.fetchQuizzes() }
        .onChange(of: course.id) {
            manager = QuizzesViewModel(courseId: course.id)
            Task { await manager.fetchQuizzes() }
        }
    }
}
