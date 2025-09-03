import SwiftUI
import WebKit

struct QuizDetailView: View {
	let quiz: Quiz

	private var isFileSubmission: Bool {
		// return true
		quiz.questionTypes.contains(QuizQuestionType.fileUploadQuestion)
	}

	var body: some View {
			// File submission quiz: Display details natively
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

				LabeledContent("Points Possible", value: "\(quiz.pointsPossible)")
			}
		}
		.navigationTitle("Quiz Details")
		.formStyle(.grouped)
		.openInCanvasToolbarButton(.quizzes(quiz.courseID ?? "MISSING_COURSE_ID", quiz.id))
	}
}
