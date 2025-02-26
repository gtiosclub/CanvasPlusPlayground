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

    init(courseId: String) {
        self.quizzesVM = QuizzesViewModel(courseId: courseId)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(quizzesVM.sections) { section in
                    quizSection(for: section)
                }
            }
            .task {
                await loadQuizzes()
            }
            .statusToolbarItem("Quizzes", isVisible: isLoadingQuizzes)
        }
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
                Text("Due at \(quiz.dueAt?.formatted(Date.FormatStyle()) ?? "Unknown")")
            }
        }
    }

    private func loadQuizzes() async {
        isLoadingQuizzes = true
        await quizzesVM.fetchQuizzes()
        isLoadingQuizzes = false
    }
}
