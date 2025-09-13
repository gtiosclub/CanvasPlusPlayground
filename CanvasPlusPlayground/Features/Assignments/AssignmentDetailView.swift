//
//  AssignmentDetailView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 2/7/25.
//

import SwiftUI

struct AssignmentDetailView: View {
    var assignment: Assignment // currently displayed assignment
    

    @State private var submission: Submission?

    // Presentable sheets
    @State private var showSubmissionPopUp: Bool = false
    @State private var showSubmissionHistoryPopUp: Bool = false
    @State private var fetchingCanSubmitStatus: Bool = false
    @State private var canSubmit: Bool = false // this is updated by a network call upon onAppear()
    @Environment(ProfileManager.self) private var profileManager 
    
    var body: some View {
        if assignment.isOnlineQuiz {
            if let url = URL(string: assignment.htmlUrl ?? "gatech.edu") {
                WebView(url: url)
            } else {
                fatalError("Invalid URL for online quiz: \(assignment.htmlUrl ?? "nil")")
            }
        } else {
            AssignmentQuizDetailsForm(item: assignment) {
                submissionSection
            }
            .toolbar {
                ReminderButton(item: .assignment(assignment))
            }
            .task {
                await fetchSubmissions()
                await fetchCanSubmitStatus()
            }
            .sheet(isPresented: $showSubmissionPopUp) {
                AssignmentCreateSubmissionView(assignment: assignment)
            }
            .sheet(isPresented: $showSubmissionHistoryPopUp) {
                if let submission {
                    SubmissionHistoryDetailView(submission: submission)
                } else {
                    submissionUnavailableView
                }
            }
            .openInCanvasToolbarButton(.assignment(assignment.courseId?.asString ?? "MISSING_COURSE_ID", assignment.id))
        }
    }
    
    var submissionUnavailableView: some View {
        ContentUnavailableView(
            "Could not load submission",
            systemImage: "exclamationmark.triangle.fill"
        )
    }
    
    // displays fields related to assignment object
    var detailsSection: some View {
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
    }
    
    var submissionSection: some View {
        Section("Submission") {
            if let allowedExtensions = assignment.allowedExtensions {
                LabeledContent(
                    "Submission Types",
                    value: allowedExtensions
                        .joined(separator: ", ")
                )
            }

            
            // everything below required a submission to exist
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
                    ProgressView()
                        .controlSize(.small)
                }
            }
            
            if let submission = self.submission {
                LabeledContent("Submission History") {
                    Button("View submission history...") {
                        showSubmissionHistoryPopUp.toggle()
                    }
                }
            }
        }
    }

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
    
    private func fetchSubmissions() async {
        guard let userId = profileManager.currentUser?.id else {
            print("Unable to get current user ID")
            return
        }
        guard let courseId: String = assignment.courseId.map({ String($0) }) else {
            print("Unable to get course ID")
            return
        }

        let request = CanvasRequest.getSubmissionHistoryForAssignment(courseId: courseId, assignmentId: assignment.id, userId: userId)
        
        let submission = try? await CanvasService.shared.loadAndSync(request, onCacheReceive: { cachedSubmission in
            guard let cachedSubmission else { return }
            self.submission = cachedSubmission.first
        })
        
        self.submission = submission?.first
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

