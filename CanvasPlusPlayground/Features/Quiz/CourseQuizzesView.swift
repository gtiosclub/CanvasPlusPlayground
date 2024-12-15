//
//  Quizzes.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/15/24.
//

import SwiftUI

struct CourseQuizzesView: View {
    @State var quizzesVM: QuizzesViewModel
    
    init(courseId: String) {
        self.quizzesVM = QuizzesViewModel(courseId: courseId)
    }
    
    var body: some View {
        List {
            ForEach(quizzesVM.sections) { section in
                quizSection(for: section)
            }
        }
        .task {
            await quizzesVM.fetchQuizzes()
        }
    }
    
    @ViewBuilder
    func quizSection(for quizType: QuizType) -> some View {
        Section(quizType.title) {
            let quizzes = quizzesVM.sectionsToQuizzes[quizType] ?? []
            ForEach(quizzes) {
                Text($0.title ?? "No Title")
            }
        }
    }
}
