//
//  AssignmentSubmissionView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 3/5/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct AssignmentSubmissionView: View {
    @State private var manager: AssignmentSubmissionManager
    var assignment: Assignment
    @State private var selectedSubmissionType: SubmissionType?
    var submissionTypes: [SubmissionType] {
        assignment.submissionTypes ?? []
    }
    @Environment(\.dismiss) private var dismiss
    @State private var showSubmissionUploadProgress = false
    @State private var isFileHover: Bool = false

    @State private var error: AssignmentSubmissionManager.AssignmentSubmissionError?

    private var showErrorAlert: Binding<Bool> {
        Binding<Bool>(
            get: { error != nil },
            set: {
                if !$0 {
                    error = nil
                }
            }
        )
    }

    init(assignment: Assignment) {
        self.assignment = assignment
        self.manager = AssignmentSubmissionManager(assignment: assignment)
    }

    // All the state variables corresponding to the data for each type
    @State private var urlTextField: String = ""
    @State private var textbox: String = ""
    @State private var selectedURLs: [URL] = []
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
                        NoSubmissionView()
                    case .onlineTextEntry:
                        TextSubmissionView(textbox: $textbox)
                    case .onlineUrl:
                        URLSubmissionView(urlTextField: $urlTextField)
                    case .onlineUpload:
                        FileUploadView(selectedURLs: $selectedURLs)
                    default:
                        UnsupportedSubmissionView(selectedSubmissionType: selectedSubmissionType)
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
                            await submitAssignment()
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
        .alert(isPresented: showErrorAlert, error: error) { _ in
            Button("OK") { showErrorAlert.wrappedValue = false }
        } message: { _ in
            Text("Error submitting assignment.")
        }
        .overlay {
            if isFileHover {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: 4)
            }
        }
    }

    private func submitAssignment() async {
        do {
            showSubmissionUploadProgress = true
            switch selectedSubmissionType {
            case .onlineTextEntry:
                assignment.submission = try await manager.submitAssignment(withText: textbox)
            case .onlineUrl:
                assignment.submission = try await manager.submitAssignment(withURL: urlTextField)
            case .onlineUpload:
                assignment.submission = try await manager.submitFileAssignment(forFiles: selectedURLs)
            default:
                LoggerService.main.error("User attempted to submit unimlemented assignment type")
            }
            showSubmissionUploadProgress = false
            dismiss()
        } catch {
            LoggerService.main.error("Error submitting assignment: \(error.localizedDescription)")
            showSubmissionUploadProgress = false
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
    private struct NoSubmissionView: View {
        var body: some View {
            Section {
                Text("No submission/paper submission")
            }
        }
    }

    // MARK: Text submission subview
    private struct TextSubmissionView: View {
        @Binding var textbox: String
        var body: some View {
            Section("Add text") {
                TextEditor(text: $textbox)
                    .frame(minHeight: 200)
                    .lineLimit(5...10)
            }
        }
    }

    var textSubmissionValid: Bool {
        !textbox.isEmpty
    }

    // MARK: URL submission subview
    private struct URLSubmissionView: View {
        @Binding var urlTextField: String
        var body: some View {
            Section("Add URL") {
                TextField("url", text: $urlTextField)
            }
        }
    }
    // TODO: Parse url to make sure it's a valid web url
    var urlSubmissionValid: Bool { !urlTextField.isEmpty }

    // MARK: File upload submission subview
    private struct FileUploadView: View {
        @Binding var selectedURLs: [URL]
        @State private var showPicker = false
#if os(iOS)
        @State private var editMode: EditMode = .active
#endif
        var body: some View {
            Section("File upload") {
                List {
                    ForEach(selectedURLs, id: \.self) { fileURL in
                        FileRow(url: fileURL) {
                            withAnimation {
                                selectedURLs.removeAll { url in
                                    url == fileURL
                                }
                            }
                        }
                    }
                    .onDelete { indices in
                        selectedURLs.remove(atOffsets: indices)
                    }
                }
#if os(iOS)
                .environment(\.editMode, $editMode)
#endif
                Button("Pick files...", systemImage: "plus") {
                    showPicker = true
                }
                .tint(.accentColor)
                // TODO: Add dragging and dropping file to view
                .fileImporter(isPresented: $showPicker, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
                    switch result {
                    case .success(let urls):

                        selectedURLs = Array(Set(selectedURLs).union(urls))

                    case .failure(let error):
                        LoggerService.main.log("Error: \(error)")
                    }
                }
            }
        }

        private struct FileRow: View {
            let url: URL

            let onDelete: () -> Void
            var body: some View {
                HStack {
                    Text(url.lastPathComponent)

                    // The trashcan icon can just be a macOS thing. For iOS, use swipe to delete
#if os(macOS)
                    Spacer()
                    Button("Remove file", systemImage: "trash") {
                        withAnimation {
                            onDelete()
                        }
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
#endif
                }
            }
        }
    }

    var fileSubmissionValid: Bool {
        !selectedURLs.isEmpty
    }

    private struct UnsupportedSubmissionView: View {
        let selectedSubmissionType: SubmissionType

        var body: some View {
            Section {
                Text("\(selectedSubmissionType.rawValue) submissions not supported")
            }
        }
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
