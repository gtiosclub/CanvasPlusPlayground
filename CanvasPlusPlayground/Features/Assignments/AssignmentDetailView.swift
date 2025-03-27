//
//  AssignmentDetailView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 2/7/25.
//

import SwiftUI

struct AssignmentDetailView: View {
    var assignment: Assignment
    private var submission: Submission? {
        assignment.submission?.createModel()
    }
    @State private var showSubmissionPopUp: Bool = false
    @State private var canSubmit: Bool?

    var body: some View {
        if assignment.isOnlineQuiz {
            if let url = URL(string: assignment.htmlUrl ?? "gatech.edu") {
                WebView(url: url)
            } else {
                fatalError("Invalid URL for online quiz: \(assignment.htmlUrl ?? "nil")")
            }
        } else {
            Form {
                Section("Details") {
                    LabeledContent("Name", value: assignment.name)

                    if let unlockAt = assignment.unlockDate {
                        LabeledContent("Available From") {
                            Text(unlockAt, style: .time)
                            + Text(" on ") +
                            Text(unlockAt, style: .date)
                        }
                    }

                    if let dueDate = assignment.dueDate {
                        LabeledContent("Due") {
                            Text(dueDate, style: .time)
                            + Text(" on ") +
                            Text(dueDate, style: .date)
                        }
                    }

                    if let lockAt = assignment.lockDate {
                        LabeledContent("Available Until") {
                            Text(lockAt, style: .time)
                            + Text(" on ") +
                            Text(lockAt, style: .date)
                        }
                    }

                    LabeledContent(
                        "Points Possible",
                        value: assignment.formattedPointsPossible
                    )
                }

                Section("Submission") {
                    if let allowedExtensions = assignment.allowedExtensions {
                        LabeledContent(
                            "Submission Types",
                            value: allowedExtensions
                                .joined(separator: ", ")
                        )
                    }

                    if let workflowState = submission?.workflowState {
                        LabeledContent(
                            "Status",
                            value: workflowState.displayValue
                        )
                    }

                    if let submittedAt = submission?.submittedAt {
                        LabeledContent(
                            "Submitted at"
                        ) {
                            let submissionTime = Date.from(submittedAt)
                            Text(submissionTime, style: .time)
                            + Text(" on ") +
                            Text(submissionTime, style: .date)
                        }
                    }
                    LabeledContent(
                        "Grade",
                        value: assignment.formattedGrade + "/" + assignment.formattedPointsPossible
                    )

                    LabeledContent("Create submission") {
                        HStack {
                            Button("New Submission...") {
                                showSubmissionPopUp.toggle()
                            }
                            .disabled(!(canSubmit ?? false))
                            if canSubmit == nil {
                                ProgressView()
                            }
                        }
                    }
                }

                if let assignmentDescription = assignment.assignmentDescription {
                    Section {
                        HTMLTextView(
                            htmlText: assignmentDescription
                        )
                    }
                }
            }
            .formStyle(.grouped)
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

    private func fetchCanSubmitStatus() async {
        guard let courseID = assignment.courseId else { return }
        let request = CanvasRequest.getAssignment(id: assignment.id, courseId: courseID.asString, include: [.canSubmit])

        do {
            if let fetched = try await CanvasService.shared.fetch(request).first {
                canSubmit = Assignment(from: fetched).canSubmit ?? false
            }
        } catch {
            LoggerService.main.error("Failed to fetch assignment \(error)")
        }
    }

    private var pointsPossible: String {
        if let pointsPossible = assignment.pointsPossible {
            return String(pointsPossible)
        } else {
            return "--"
        }
    }

    private var grade: String {
        if let grade = submission?.grade {
            return String(grade)
        } else {
            return "--"
        }
    }
}
