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
            @State var showFileExporter: Bool = false
            @State var showProgressView: Bool = false
            var body: some View {
                HStack {
                    Text("\(file.display_name)")
                    Spacer()
                    if showProgressView {
                        ProgressView()
                            .scaleEffect(0.5)
                    } else {
                        Button(action:downloadFile) {
                            Image(systemName: "arrow.down.circle")
                        }
                    }
                }
                .fileExporter(isPresented: $showFileExporter, document: dataFileDocument, defaultFilename: file.display_name) { result in
                    switch result {
                    case .success(let url):
                        LoggerService.main.info("File saved to \(url)")
                    case .failure(let error):
                        LoggerService.main.error("Error placing submission attachment: \(error)")
                    }
                    showProgressView = false
                }

            }
            
            func downloadFile() {
                guard let urlString = file.url else { return }
                
                guard let url = URL(string: urlString) else { return }
                
                let request = URLRequest(url: url)
                showProgressView = true
                Task {
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
                    #if DEBUG
                    // for logging purposes in the request debug window
                    NetworkRequestRecorder.shared.addRecord(request: request, response: response, responseBody: data)
                    #endif
                    
                    dataFileDocument = DataFileDocument(data: data)
                    showFileExporter = true
                }
            }
        }
    }
}

// Struct used for file downloads to the user's filesystem.
// This file takes in generic data (the name of the file dictates the type w/ file exporter)
struct DataFileDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.fileURL]
    static var writableContentTypes: [UTType] = [.fileURL]
    var data: Data
    init(data: Data) {
        self.data = data
    }

    // For loading from disk (not essential for exporting)
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    // For saving to disk
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

