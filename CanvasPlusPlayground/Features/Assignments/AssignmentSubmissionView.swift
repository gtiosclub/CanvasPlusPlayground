//
//  AssignmentSubmissionView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 3/5/25.
//

import SwiftUI

struct AssignmentSubmissionView: View {
    let assignment: Assignment
    var submissionTypes: [Assignment.SubmissionType] //{
        //assignment.submissionTypes ?? [.]
    // }
    {
        [.discussionTopic, .onPaper, .onlineUpload, .onlineTextEntry]
    }
    
    @Environment(\.dismiss) var dismiss

    @State private var selectedSubmissionType: Assignment.SubmissionType?
    
    @State var urls: [URL] = []
    @State var text: String = ""
    var body: some View {
        NavigationStack {
            Form {
                if submissionTypes.count != 1 {
                    Picker("Submission Type", selection: $selectedSubmissionType) {
                        ForEach(submissionTypes, id:\.self) { type in
                            Text(type.rawValue)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if selectedSubmissionType != nil {
                    let type = selectedSubmissionType!
                    switch type {
                    case .none, .onPaper:
                        Section {
                            Text("No submission/paper submission")
                        }
                    case .onlineUrl, .onlineTextEntry:
                        AssignmentTextSubmissionView(text: $text)
                    case .onlineUpload:
                        AssignmentFileUploadView(selectedFiles: $urls)
                    default:
                        Section {
                            Text("\(type.rawValue) submissions not supported")
                        }
                        // TODO: implement .discussionTopic, .onlineQuiz, .externalTool, .mediaRecording, and .studentAnnotation
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Create submission")
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Submit") {
                    dismiss()
                }
            }
        }
        .onAppear {
            selectedSubmissionType = submissionTypes.first
        }
    }
}

struct AssignmentTextSubmissionView: View {
    @Binding var text: String
    var body: some View {
        Section("Add text") {
            TextEditor(text: $text)
                .frame(minHeight: 200)
                .lineLimit(5...10)
                .padding()
        }
    }
}

struct AssignmentFileUploadView: View {
    @Binding var selectedFiles: [URL]
    @State private var iosPicker = false
    var body: some View {
        Section("File upload") {
            ForEach(selectedFiles, id: \.self) { fileURL in
                HStack {
                    Text(fileURL.lastPathComponent)
                    Spacer()
                    Button("Remove file", systemImage: "trash") {
                        withAnimation {
                            selectedFiles.removeAll { url in
                                url == fileURL
                            }
                        }
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                }
            }
            Button("Pick files...", systemImage: "plus") {
                iosPicker = true
            }
            .buttonStyle(.borderless)
            .tint(.accentColor)
            // TODO: Add dragging and dropping file to view
            .fileImporter(isPresented: $iosPicker, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    selectedFiles.append(contentsOf: urls)
                case .failure(let error):
                    LoggerService.main.log("Error: \(error)")
                    // TODO: Add a popup for this error
                }
            }
        }
    }
}
