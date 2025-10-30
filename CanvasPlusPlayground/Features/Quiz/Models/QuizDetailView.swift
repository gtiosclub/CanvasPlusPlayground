//
//  QuizDetailView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 9/13/25.
//


import SwiftUI

struct QuizDetailView: View {
	let quiz: Quiz

	var body: some View {
		AssignmentQuizDetailsForm(item: quiz) {
			Section("Quiz Specifics") {
				if let questionCount = quiz.questionCount {
					LabeledContent("Number of Questions", value: "\(questionCount)")
				}

                LabeledContent(
                    "Allowed Attempts",
                    value: "\(quiz.displayAllowedAttempts)"
                )
			}
		}
        .handleDeepLinks(for: quiz.courseID)
		.toolbar {
			PinButton(
				itemID: quiz.assignmentID ?? quiz.id,
				courseID: quiz.courseID,
				type: .assignment
			)
		}
		.logRecentItem(
			itemID: quiz.id,
            courseID: quiz.courseID,
			type: .quiz
		)
	}
}
