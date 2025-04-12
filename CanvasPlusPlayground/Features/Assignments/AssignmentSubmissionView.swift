//
//  AssignmentSubmissionView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 3/5/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct AssignmentSubmissionView: View {
    typealias AssignmentSubmissionError = AssignmentSubmissionManager.AssignmentSubmissionError

    @Environment(\.dismiss) private var dismiss

    @State private var manager: AssignmentSubmissionManager

    let assignment: Assignment

    @State private var selectedSubmissionType: SubmissionType?
    @State private var showSubmissionUploadProgress = false
    @State private var isFileHover: Bool = false
    @State private var showFilePicker = false

    // All the state variables corresponding to the data for each type
    @State private var urlTextField: String = ""
    @State private var textbox: String = ""
    @State private var selectedURLs: [URL] = []

    @State private var error: AssignmentSubmissionError?

    var allowedFileTypes: [UTType] {
        assignment.allowedExtensions?.compactMap { UTType(filenameExtension: $0) } ?? [.item]
    }

    var submissionTypes: [SubmissionType] {
        assignment.submissionTypes ?? []
    }

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
                        FileUploadView(
                            selectedURLs: $selectedURLs,
                            showPicker: $showFilePicker
                        )
                    default:
                        UnsupportedSubmissionView(selectedSubmissionType: selectedSubmissionType)
                        // TODO: implement .discussionTopic, .onlineQuiz, .externalTool, .mediaRecording, and .studentAnnotation
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Create Submission")
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
        } message: { error in
            Text("Error submitting assignment: \(error.localizedDescription)")
        }
        .overlay {
            if isFileHover {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: 4)
            }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: allowedFileTypes, allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                selectedURLs = Array(Set(selectedURLs).union(urls))
            case .failure(let error):
                LoggerService.main.log("Error: \(error)")
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

            if let error = error as? AssignmentSubmissionError {
                self.error = error
            }

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

    var textSubmissionValid: Bool {
        !textbox.isEmpty
    }

    // TODO: Parse url to make sure it's a valid web url
    var urlSubmissionValid: Bool { !urlTextField.isEmpty }

    var fileSubmissionValid: Bool {
        !selectedURLs.isEmpty
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers.filter({ $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async {
                        guard let type = UTType(filenameExtension: url.pathExtension) else {
                            error = AssignmentSubmissionError.invalidFileType
                            showErrorAlert.wrappedValue = true
                            return
                        }
                        if allowedFileTypes.contains(where: { allowedType in
                            type.conforms(to: allowedType)
                        }) {
                            selectedURLs.append(url)
                        } else {
                            error = AssignmentSubmissionError.invalidFileType
                            showErrorAlert.wrappedValue = true
                        }
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

// MARK: - URL submission subview
private struct URLSubmissionView: View {
    @Binding var urlTextField: String

    var body: some View {
        Section("Add URL") {
            TextField("url", text: $urlTextField)
        }
    }
}

// MARK: - Paper/No submission subview
private struct NoSubmissionView: View {
    var body: some View {
        ContentUnavailableView(
            "Unsupported Submission Type",
            systemImage: "doc.fill",
            description: Text("No Submission or Paper Submission")
        )
    }
}

// MARK: - Text submission subview
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

// MARK: - Unsupported submission subview
private struct UnsupportedSubmissionView: View {
    let selectedSubmissionType: SubmissionType

    var body: some View {
        ContentUnavailableView(
            "Unsupported Submission Type",
            systemImage: "doc.questionmark.fill",
            description: Text("\(selectedSubmissionType.displayName) submissions not supported")
        )
    }
}

// MARK: - File upload submission subview
private struct FileUploadView: View {
    @Binding var selectedURLs: [URL]
    @Binding var showPicker: Bool

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

                Button("Pick files...", systemImage: "plus") {
                    showPicker.toggle()
                }
                .tint(.accentColor)
                .padding(.vertical, 2)
            }
            #if os(iOS)
            .environment(\.editMode, $editMode)
            #endif
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
            .padding(.vertical, 2)
        }
    }
}
