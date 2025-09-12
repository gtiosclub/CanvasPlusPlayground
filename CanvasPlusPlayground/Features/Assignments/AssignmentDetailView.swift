//
//  AssignmentDetailView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 2/7/25.
//


import SwiftUI

struct AssignmentDetailView: View {
	var assignment: Assignment

	// All assignment-specific state and logic remains here
	private var submission: Submission? {
		assignment.submission?.createModel()
	}
	@State private var showSubmissionPopUp: Bool = false
	@State private var fetchingCanSubmitStatus: Bool = false
	@State private var canSubmit: Bool?

	var body: some View {
		if assignment.isOnlineQuiz {
			// Unique logic for online quizzes is preserved
			if let url = URL(string: assignment.htmlUrl ?? "gatech.edu") {
				WebView(url: url)
			} else {
				fatalError("Invalid URL for online quiz: \(assignment.htmlUrl ?? "nil")")
			}
		} else {
			// Use the generic view for the standard assignment layout
			DetailsView(item: assignment) {
				// The entire "Submission" section is injected as additional content
				Section("Submission") {
					if let allowedExtensions = assignment.allowedExtensions {
						LabeledContent("Submission Types", value: allowedExtensions.joined(separator: ", "))
					}
					if let workflowState = submission?.workflowState {
						LabeledContent("Status", value: workflowState.displayValue)
					}
					if let submittedAt = submission?.submittedAt {
						LabeledContent("Submitted at") {
							let submissionTime = Date.from(submittedAt)
							Text(submissionTime, style: .time) + Text(" on ") + Text(submissionTime, style: .date)
						}
					}
					LabeledContent("Grade", value: assignment.formattedGrade + "/" + assignment.formattedPointsPossible)
					
					HStack {
						let submissionsClosed = !(canSubmit ?? false)
						#if os(macOS)
						Spacer()
						#endif
						Button(submissionsClosed ? "Submissions Closed" : "New Submission...") {
							showSubmissionPopUp.toggle()
						}
						.disabled(submissionsClosed)

						if fetchingCanSubmitStatus {
							ProgressView().controlSize(.small)
						}
					}
				}
			}
			// All specific modifiers are applied to the composed view
			.toolbar {
				ReminderButton(item: .assignment(assignment))
			}
			.task {
				await fetchCanSubmitStatus()
			}
			.sheet(isPresented: $showSubmissionPopUp) {
				AssignmentSubmissionView(assignment: assignment)
			}
		}
	}
	
	// All assignment-specific functions remain here
	private func fetchCanSubmitStatus() async {
		guard let courseID = assignment.courseId else { return }
		fetchingCanSubmitStatus = true
		let request = CanvasRequest.getAssignment(id: assignment.id, courseId: courseID.asString, include: [.canSubmit])
		do {
			if let fetched = try await CanvasService.shared.fetch(request).first {
				canSubmit = Assignment(from: fetched).canSubmit ?? false
			}
		} catch {
			LoggerService.main.error("Failed to fetch assignment \(error)")
		}
		fetchingCanSubmitStatus = false
	}
}
