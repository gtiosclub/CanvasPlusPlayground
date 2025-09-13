//
//  FileViewer.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/9/24.
//

import SwiftUI


struct FileViewer: View {
    @Environment(\.dismiss) private var dismiss

    let courseID: Course.ID
    let file: File
    let fileService = CourseFileService()

    @State private var url: URL?
    @State private var isLoading = false

    #if os(macOS)
    @State private var destinationURL: URL?
    #endif

    var body: some View {
        Group {
            if let url {
                QuickLookPreview(url: url) { dismiss() }
                    #if os(iOS)
                    .ignoresSafeArea()
                    .toolbar(.hidden)
                    #else
                    .toolbar {
                        ToolbarItemGroup {
                            ShareLink(item: url)
                            DownloadButton(url: url, fileName: file.displayName)
                        }
                    }
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
            } catch {
                LoggerService.main.error("Failed to save file: \(error.localizedDescription)")
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

