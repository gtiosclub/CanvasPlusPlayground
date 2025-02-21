//
//  AssignmentDetailView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 2/7/25.
//

import SwiftUI

struct AssignmentDetailView: View {
    let assignment: Assignment
    @State private var submission: Submission?

    var body: some View {
        if assignment.isOnlineQuiz {
            WebView(url: URL(string: assignment.htmlUrl ?? "gatech.edu")!)
        } else {
            Form {
                Section("Details") {
                    LabeledContent("Name", value: assignment.name)

                    if let unlockAt = assignment.unlockDate {
                        LabeledContent(
                            "Available From",
                            value: unlockAt.formatted()
                        )
                    }

                    if let dueDate = assignment.dueDate {
                        LabeledContent("Due", value: dueDate.formatted())
                    }

                    if let lockAt = assignment.lockDate {
                        LabeledContent(
                            "Available Until",
                            value: lockAt.formatted()
                        )
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

                    LabeledContent(
                        "Grade",
                        value: assignment.formattedGrade + "/" + assignment.formattedPointsPossible
                    )
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
            .task {
                submission = assignment.submission?.createModel()
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
