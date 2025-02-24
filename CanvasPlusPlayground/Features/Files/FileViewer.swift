//
//  FileViewer.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/9/24.
//

import SwiftUI

struct FileViewer: View {
    @Environment(\.dismiss) private var dismiss

    let course: Course
    let file: File
    let fileService = CourseFileService()

    @Environment(CourseFileViewModel.self) var courseFileVM
    @State private var url: URL?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let url {
                QuickLookPreview(url: url) { dismiss() }
                    #if os(iOS)
                    .navigationBarBackButtonHidden()
                    .ignoresSafeArea()
                    #else
                    .toolbar {
                        ShareLink(item: url)
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
    }

    private func loadContents() async {
        isLoading = true
        do {
            (_, self.url) = try await fileService.courseFile(
                for: file,
                course: course,
                foldersPath: courseFileVM.traversedFolderIDs,
                localCopyReceived: { (_, self.url) = ($0, $1) }
            )
        } catch {
            logger.error("Error fetching file content: \(error)")
        }
        self.isLoading = false
    }
}
