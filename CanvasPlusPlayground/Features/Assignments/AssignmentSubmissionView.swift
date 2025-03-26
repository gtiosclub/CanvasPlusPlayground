//
//  AssignmentSubmissionView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 3/5/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct AssignmentSubmissionView: View {
    @Environment(AssignmentSubmissionManager.self) private var manager
    @Binding var assignment: Assignment
    @State private var selectedSubmissionType: SubmissionType?
    // TODO: Expand supported types beyond [.onlineUrl, .onlineUpload, .onlineTextEntry, .onPaper]
    var submissionTypes: [SubmissionType] {
        assignment.submissionTypes ?? []
    }
    @Environment(\.dismiss) private var dismiss
    @State private var showSubmissionUploadProgress = false
    @State private var showSubmissionErrorAlert: Bool = false
    @State private var alertText:String = ""

    @State private var isFileHover: Bool = false
    var body: some View {
        NavigationStack {
            Form {
                if submissionTypes.count != 1 {
                    Picker("Submission Type", selection: $selectedSubmissionType) {
                        ForEach(submissionTypes, id:\.self) { type in
                            Text(type.displayName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if let selectedSubmissionType {
                    switch selectedSubmissionType {
                    case .none, .onPaper:
                        noSubmissionView
                    case .onlineTextEntry:
                        textSubmissionView
                    case .onlineUrl:
                        urlSubmissionView
                    case .onlineUpload:
                        fileUploadView
                    default:
                        Section {
                            Text("\(selectedSubmissionType.rawValue) submissions not supported")
                        }
                        // TODO: implement .discussionTopic, .onlineQuiz, .externalTool, .mediaRecording, and .studentAnnotation
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Create submission")
            .overlay {
                if showSubmissionUploadProgress {
                    ProgressView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task {
                            do {
                                showSubmissionUploadProgress = true
                                switch selectedSubmissionType {
                                case .onlineUrl:
                                    assignment.submission = try await manager.submitAssignment(withText: textbox)
                                case .onlineTextEntry:
                                    assignment.submission = try await manager.submitAssignment(withURL: urlTextField)
                                case .onlineUpload:
                                    assignment.submission = try await manager.submitFileAssignment(forFiles: selectedURLs)
                                default:
                                    LoggerService.main.error("User attempted to submit unimlemented assignment type")
                                }
                                showSubmissionUploadProgress = false
                                dismiss()
                            } catch {
                                // TODO: We could display error information to the user here
                                LoggerService.main.error("Error submitting assignment: \(error.localizedDescription)")
                                alertText = error.localizedDescription
                                showSubmissionErrorAlert = true
                                showSubmissionUploadProgress = false
                            }
                        }
                    }
                    .disabled(submitButtonDisabled)
                }
            }
            .onDrop(of: [UTType.fileURL], isTargeted: $isFileHover) { providers in
                handleDrop(providers: providers)
            }
        }
        .onAppear {
            selectedSubmissionType = submissionTypes.first
        }
        .alert("Error submitting assignment", isPresented: $showSubmissionErrorAlert) {
            Button("Dismiss") { }
        } message: {
            Text(alertText)
        }
        .overlay {
            if isFileHover {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: 4)
            }
        }
    }

    var submitButtonDisabled:Bool {
        guard let selectedSubmissionType else {
            return true
        }
        switch selectedSubmissionType {
        case .onlineTextEntry:
            return !textSubmissionValid
        case .onlineUrl:
            return !urlSubmissionValid
        case .onlineUpload:
            return !fileSubmissionValid
        default:
            return true
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
    var textSubmissionValid: Bool {
        !textbox.isEmpty
    }

    // MARK: URL submission subview
    @State private var urlTextField: String = ""
    var urlSubmissionView: some View {
        Section("Add URL") {
            TextField("url", text: $urlTextField)
        }
    }
    // TODO: Parse url to make sure it's a valid web url
    var urlSubmissionValid: Bool { !urlTextField.isEmpty }

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
                    showSubmissionErrorAlert = true
                }
            }
        }
    }

    var fileSubmissionValid: Bool {
        !selectedURLs.isEmpty
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers.filter({ $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async {
                        selectedURLs.append(url)
                    }
                } else {
                    LoggerService.main.error("Failed to load file URL")
                }
            }
            return true
        }
        return false
    }
}
