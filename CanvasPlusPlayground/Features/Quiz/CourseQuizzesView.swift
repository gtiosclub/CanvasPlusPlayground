//
//  Quizzes.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/15/24.
//

import SwiftUI

struct CourseQuizzesView: View {
    @State private var quizzesVM: QuizzesViewModel

    @State private var isLoadingQuizzes = true

    @State private var selectedQuiz: Quiz?

    init(courseId: String) {
        self.quizzesVM = QuizzesViewModel(courseId: courseId)
    }

    var body : some View {
        mainbody
            #if os(iOS)
            .onAppear {
                selectedQuiz = nil
            }
            #endif
    }

    var mainbody: some View {
        List(selection: $selectedQuiz) {
            ForEach(quizzesVM.sections) { section in
                quizSection(for: section)
            }
        }
        .task {
            await loadQuizzes()
        }
        .statusToolbarItem("Quizzes", isVisible: isLoadingQuizzes)
    }

    @ViewBuilder
    func quizSection(for quizType: QuizType) -> some View {
        Section(quizType.title) {
            let quizzes = quizzesVM.sectionsToQuizzes[quizType] ?? []
            ForEach(quizzes) {
                quizCell(for: $0)
            }
        }
    }

    @ViewBuilder
    func quizCell(for quiz: Quiz) -> some View {
        NavigationLink(
            value: NavigationModel.Destination.quiz(quiz)) {
            HStack {
                VStack {
                    Text(quiz.title)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        if let pointsPossible = quiz.pointsPossible?.truncatingTrailingZeros {
                            Text("\(pointsPossible) pts")
                        } else { Text("No pts")}

                        Text("\(quiz.questionCount ?? 0) Questions")
                        Text("Allowed Attempts: \(quiz.allowedAttempts)")
                    }
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                if quiz.lockedForUser == true {
                    Text("Closed")
                } else if quiz.dueAt == .distantFuture {
                    Text("No Due Date")
                } else {
                    if let dueDate = quiz.dueAt {
                        if dueDate < Date() {
                            Text("Due at \(dueDate.formatted(Date.FormatStyle()))")
                                .strikethrough()
                                .foregroundColor(.gray)
                            Text("Past Due")
                                .bold()
                                .foregroundColor(.red)
                        } else {
                            Text("Due at \(dueDate.formatted(Date.FormatStyle()))")
                        }
                    } else {
                        Text("Due at Unknown")
                    }
                }
            }
        }
        .contextMenu {
            OpenInCanvasButton(path: .quizzes(quiz.courseID, quiz.id))
        }
        .tag(quiz)
    }

    private func loadQuizzes() async {
        isLoadingQuizzes = true
        await quizzesVM.fetchQuizzes()
        isLoadingQuizzes = false
    }
}
