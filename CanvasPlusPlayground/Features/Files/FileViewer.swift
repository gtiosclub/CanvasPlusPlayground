//
//  FileViewer.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/9/24.
//

import SwiftUI

#if os(macOS)
enum DownloadStatus {
    case inactive
    case success
    case error
}
#endif

struct FileViewer: View {
    @Environment(\.dismiss) private var dismiss

    let courseID: Course.ID
    let file: File
    let fileService = CourseFileService()

    @State private var url: URL?
    @State private var isLoading = false

    #if os(macOS)
    @State private var downloadStatus = DownloadStatus.inactive
    @State private var destinationURL: URL?

    var alertTitle: String {
        switch downloadStatus {
        case .success:
            return "\(file.displayName) saved"
        case .error:
            return "Download failed"
        default:
            return ""
        }
    }

    var alertMessage: String? {
        switch downloadStatus {
        case .success:
            if let destinationURL {
                return "The file was saved to: \(destinationURL.description)"
            } else {
                return "The file was saved to your chosen location"
            }

        case .error:
            return "Please try again."
        default:
            return nil
        }
    }

    var presentAlert: Binding<Bool> {
        Binding<Bool>(
            get: { downloadStatus == .success || downloadStatus == .error },
            set: { newValue in
                if newValue == false {
                    downloadStatus = .inactive
                }
            }
        )
    }
    #endif

    var body: some View {
        Group {
            if let url {
                QuickLookPreview(url: url) { dismiss() }
                    #if os(iOS)
                    .ignoresSafeArea()
                    .toolbar(.hidden)
                    #else
                    .macOSToolbarForFileViewer(url: url) { url in downloadFile(from: url) }
                    .macOSFileDownloadAlert(
                        alertTitle: alertTitle,
                        presentAlert: presentAlert,
                        alertMessage: alertMessage,
                        downloadStatus: $downloadStatus
                    )
                    #endif
            } else {
                Group {
                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading...")
                        }
                    } else {
                        ContentUnavailableView("Unable to preview file.", systemImage: "xmark.rectangle.fill")
                    }
                }
                #if os(iOS)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
                #endif
            }
        }
        .task {
            await loadContents()
        }
        .navigationTitle(file.displayName)
        #if os(iOS)
        .navigationBarBackButtonHidden()
        #endif
    }

    #if os(macOS)
    private func downloadFile(from sourceURL: URL?) {
        guard let sourceURL else { return }
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = file.displayName
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.allowsOtherFileTypes = true

        if savePanel.runModal() == .OK, let destinationURL = savePanel.url {
            do {
                // Remove existing file if present
                self.destinationURL = destinationURL
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                downloadStatus = .success
            } catch {
                LoggerService.main.error("Failed to save file: \(error.localizedDescription)")
                downloadStatus = .error
            }
        }
    }
    #endif

    private func loadContents() async {
        isLoading = true
        do {
            (_, self.url) = try await fileService.courseFile(
                for: file,
                courseID: courseID,
                localCopyReceived: { (_, url) = ($0, $1) }
            )
        } catch {
            LoggerService.main.error("Error fetching file content: \(error)")
        }
        self.isLoading = false
    }
}

#if os(macOS)
extension View {
    func macOSToolbarForFileViewer(url: URL, downloadAction: @escaping (URL) -> Void) -> some View {
        self
            .toolbar {
                ToolbarItemGroup {
                    ShareLink(item: url)
                    Button {
                        downloadAction(url)
                    } label: {
                        Label("Download", systemImage: "arrow.down.circle")
                    }
                }
            }
    }

    func macOSFileDownloadAlert(alertTitle: String, presentAlert: Binding<Bool>, alertMessage: String?, downloadStatus: Binding<DownloadStatus>) -> some View {
        self
            .alert(alertTitle, isPresented: presentAlert) {
                Button("OK") { downloadStatus.wrappedValue = .inactive }
            } message: {
                if let alertMessage {
                    VStack(alignment: .center) {
                        Text(alertMessage)
                    }
                    .padding()
                }
            }
    }
}
#endif
