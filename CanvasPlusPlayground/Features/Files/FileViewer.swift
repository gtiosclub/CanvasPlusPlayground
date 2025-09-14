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

    var body: some View {
        Group {
            if let url {
                QuickLookPreview(url: url) { dismiss() }
                    #if os(iOS)
                    .ignoresSafeArea()
                    .toolbar(.hidden)
                    #else
                    .toolbar {
                        ToolbarItemGroup() {
                            ShareLink(item: url)
                            PinButton(
                                itemID: file.id,
                                courseID: courseID,
                                type: .file
                            )
                        }
                    }                    #endif
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
