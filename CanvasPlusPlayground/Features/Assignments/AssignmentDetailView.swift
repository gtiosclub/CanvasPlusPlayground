//
//  AssignmentDetailView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 2/7/25.
//

import SwiftUI

struct AssignmentDetailView: View {
    @State private var assignment: Assignment
    private var submission: Submission? {
        assignment.submission?.createModel()
    }
    @State private var showSubmissionPopUp: Bool = false
    @State private var canSubmit = false
    init(assignment: Assignment) {
        self.assignment = assignment
    }

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
                            "Submitted at",
                            value: submittedAt
                        )
                    }
                    LabeledContent(
                        "Grade",
                        value: assignment.formattedGrade + "/" + assignment.formattedPointsPossible
                    )
                    if canSubmit {
                        LabeledContent("Create submission") {
                            Button("Create Submission...") {
                                showSubmissionPopUp.toggle()
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
            .sheet(isPresented: $showSubmissionPopUp) {
                AssignmentSubmissionView(assignment: $assignment)
                    .environment(AssignmentSubmissionManager(assignment: assignment))
            }
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
