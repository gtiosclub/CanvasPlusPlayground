//
//  AssignmentSubmissionView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 3/5/25.
//

import SwiftUI

struct AssignmentSubmissionView: View {
    @Environment(AssignmentSubmissionManager.self) var manager
    let assignment: Assignment
    @State private var selectedSubmissionType: SubmissionType?
    var submissionTypes: [SubmissionType] {
        assignment.submissionTypes ?? []
    }
    @Environment(\.dismiss) var dismiss

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
                        noSubmissionView
                    case .onlineUrl, .onlineTextEntry:
                        textSubmissionView
                    case .onlineUpload:
                        fileUploadView
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
                Button("File submit") {
                    Task {
                        switch selectedSubmissionType! {
                        case .onlineUrl:
                            await manager.submitAssignment(withText: textbox)
                        case .onlineUpload:
                            await manager.submitFileAssignment(forFiles: selectedURLs)
                        default:
                            print("unimplemented")
                        }
                    }
                }
                // .disabled(submitDisabled)
            }
        }
        .onAppear {
            selectedSubmissionType = submissionTypes.first
        }
    }

    // MARK: Should the submit button be enabled or not
    var submitDisabled: Bool {
        guard let selectedSubmissionType else {
            return true
        }
        switch selectedSubmissionType {
        case .onlineUrl:
            return selectedURLs.isEmpty
        case .onlineTextEntry:
            return textbox.isEmpty
        default:
            return true
        }
    }

    // MARK: Paper/No submission subview
    var noSubmissionView: some View {
        Section {
            Text("No submission/paper submission")
        }
    }

    // MARK: Text submission subview
    @State private var textbox: String = ""
    var textSubmissionView: some View {
        Section("Add text") {
            TextEditor(text: $textbox)
                .frame(minHeight: 200)
                .lineLimit(5...10)
                .padding()
        }
    }

    // MARK: File upload submission subview
    @State private var selectedURLs: [URL] = []
    @State private var iosPicker = false
    var fileUploadView: some View {
        Section("File upload") {
            ForEach(selectedURLs, id: \.self) { fileURL in
                HStack {
                    Text(fileURL.lastPathComponent)
                    Spacer()
                    Button("Remove file", systemImage: "trash") {
                        withAnimation {
                            selectedURLs.removeAll { url in
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
                    selectedURLs.append(contentsOf: urls)
                case .failure(let error):
                    LoggerService.main.log("Error: \(error)")
                    // TODO: Add a popup for this error
                }
            }
        }
    }

    // MARK: URL Submission
    // TODO: Implement URL submission
}
