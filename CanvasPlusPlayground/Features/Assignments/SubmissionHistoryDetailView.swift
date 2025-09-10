//
//  SubmissionHistoryDetailView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/6/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct SubmissionHistoryDetailView: View {
    
    @Environment(\.dismiss) var dismiss
    
    let submission: Submission
    
    var submissionComments:[SubmissionComment] {
        submission.submissionComments ?? []
    }
    
    var submissionHistory:[Submission] {
        guard var history = submission.submissionHistory else { return [] }
        history.removeAll { submission in
            submission.attempt == self.submission.attempt // can't use the id, they're all the same
        }
        
        return history
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // display current submission info
                Section("Current Submission") {
                    SubmissionListCell(submission: self.submission)
                }
                
                // display previous submission info
                if !submissionHistory.isEmpty {
                    Section("Previous Submissions") {
                        ForEach(submissionHistory.reversed(), id:\.attempt) { prev in
                            SubmissionListCell(submission: prev)
                        }
                    }
                }
                
                // display submission comments
                if !submissionComments.isEmpty {
                    Section("Comments") {
                        ForEach(submissionComments) { comment in
                            Text(comment.comment)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Submission History")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
    
    private struct SubmissionListCell: View {
        let submission: Submission
        
        var submissionTimeString: String {
            let dateTime = Date.from(submission.submittedAt ?? "")
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .long
            return formatter.string(from: dateTime)
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                LabeledContent("Attempt", value: String(submission.attempt ?? 0))
                LabeledContent("Grade", value: submission.grade ?? "N/A")
                LabeledContent("Score", value: submission.score?.description ?? "N/A")
                LabeledContent("Submitted at", value: self.submissionTimeString)
                if let body = submission.body, !body.isEmpty {
                    Text(body).font(.footnote)
                }
                if !self.submission.attachments.isEmpty {
                    Text("Submission Attachments")
                        .font(.headline)
                        .padding(EdgeInsets(top:10, leading:0, bottom:0, trailing:0))
                    Divider()
                    ForEach(self.submission.attachments) { file in
                        SumbissionAttachmentListCell(file: file)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        
        private struct SumbissionAttachmentListCell: View {
            let file: FileAPI
            @State var dataFileDocument: DataFileDocument?
            @State var showProgressView: Bool = false
            var body: some View {
                HStack {
                    Text("\(file.display_name)")
                    
                    if let url = URL(string: file.url ?? "") {
                        Spacer()
                        DownloadButton(url: url, fileName: file.display_name)
                    }
                }
            }
        }
    }
}
