//
//  QuizViewModel.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/15/24.
//

import Foundation

@Observable
class QuizzesViewModel {
    let courseId: String
    var quizzes = Set<Quiz>()

    var sectionsToQuizzes: [QuizType: [Quiz]] {
        let unsorted = Dictionary(grouping: quizzes, by: { $0.quizType })

        return unsorted.mapValues {
            $0.sorted {
                if $0.dueAt == $1.dueAt {
                    $0.title < $1.title
                } else { ($0.dueAt ?? .now) < $1.dueAt ?? .now }
            }
        }
    }
    var sections: [QuizType] {
        Array(self.sectionsToQuizzes.keys)
            .sorted { $0.title < $1.title }
    }

    init(courseId: String) {
        self.courseId = courseId
    }

    func fetchQuizzes() async {
        let request = CanvasRequest.getQuizzes(courseId: courseId)

        do {
            let _: [Quiz] = try await CanvasService.shared.loadAndSync(
                request,
                onCacheReceive: {
                    guard let quizzes = $0 else { return }
                    addQuizzes(quizzes)
                },
                loadingMethod: .all(onNewPage: addQuizzes)
            )

        } catch {
            LoggerService.main.error("Quiz fetch failed with error: \n\(error)")
        }

    }

    func addQuizzes(_ newQuizzes: [Quiz]) {
        Task { @MainActor in
            self.quizzes.formUnion(newQuizzes)
        }
    }

}
