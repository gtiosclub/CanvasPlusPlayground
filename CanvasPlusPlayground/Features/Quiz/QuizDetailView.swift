import SwiftUI
import WebKit

struct QuizDetailView: View {
	let quiz: Quiz

	private var isFileSubmission: Bool {
		quiz.questionTypes.contains(QuizQuestionType.fileUploadQuestion)
	}

	var body: some View {
		VStack {
			// Display quiz details
			Form {
				Section("Details") {
					LabeledContent("Name", value: quiz.title)

					if let unlockAt = quiz.unlockAt {
						LabeledContent("Available From") {
							Text(unlockAt, style: .time)
							+ Text(" on ") +
							Text(unlockAt, style: .date)
						}
					}

					if let dueDate = quiz.dueAt {
						LabeledContent("Due") {
							Text(dueDate, style: .time)
							+ Text(" on ") +
							Text(dueDate, style: .date)
						}
					}

					if let lockAt = quiz.lockAt {
						LabeledContent("Available Until") {
							Text(lockAt, style: .time)
							+ Text(" on ") +
							Text(lockAt, style: .date)
						}
					}

					LabeledContent("Points Possible", value: "\(quiz.pointsPossible ?? 0)")

					if let questionCount = quiz.questionCount {
						LabeledContent("Number of Questions", value: "\(questionCount)")
					}

					LabeledContent("Allowed Attempts", value: "\(quiz.allowedAttempts)")
				}

				if let details = quiz.details, !details.isEmpty {
					Section("Description") {
						HTMLTextView(
							htmlText: quiz.details ?? ""
						)
					}
				}
			}

			// Open in Canvas button at the bottom
			OpenInCanvasButton(path: .quizzes(quiz.courseID, quiz.id))
				.padding()
		}
		.navigationTitle("Quiz Details")
		.formStyle(.grouped)
	}
}
