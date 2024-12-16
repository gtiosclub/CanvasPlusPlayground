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
        NavigationStack {
            List {
                ForEach(quizzesVM.sections) { section in
                    quizSection(for: section)
                }
            }
            .task {
                await quizzesVM.fetchQuizzes()
            }
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
                Text(quiz.title ?? "No Title")
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    if let pointsPossible = quiz.pointsPossible?.truncatingTrailingZeros {
                        Text("\(pointsPossible) pts")
                            
                    } else { Text("No pts")}
                    
                    Text("\(quiz.questionCount?.toInt ?? 0) Questions")
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
                Text("Due at \(quiz.dueAt.formatted(Date.FormatStyle()))")
            }
        }
    }
}
