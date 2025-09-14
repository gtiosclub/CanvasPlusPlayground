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
        .navigationTitle("Quizzes")
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
                        Text("Allowed Attempts: \(quiz.displayAllowedAttempts)")
                    }
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
        }
        .contextMenu {
            OpenInCanvasButton(path: .quizzes(quiz.courseID, quiz.id))
            NewWindowButton(destination: .quiz(quiz))
        }
        .tag(quiz)
    }

    private func loadQuizzes() async {
        isLoadingQuizzes = true
        await quizzesVM.fetchQuizzes()
        isLoadingQuizzes = false
    }
}
