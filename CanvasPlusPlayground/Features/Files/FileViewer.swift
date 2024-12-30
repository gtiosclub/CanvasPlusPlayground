//
//  FileViewer.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/9/24.
//

import SwiftUI

struct FileViewer: View {
    let course: Course
    let file: File
    let fileService = CourseFileService()

    @Environment(CourseFileViewModel.self) var courseFileVM
    @State var content: Data?

    var fileType: FileType? {
        FileType.fromFile(file)
    }

    var body: some View {
        VStack {
            if let content, let fileType {
                switch fileType {
                case .latex:
                    EmptyView()
                case .docx:
                    EmptyView()
                case .pdf:
                    CoursePDFView(source: .data(content))
                }
            } else if content != nil {
                ContentUnavailableView("Preview not supported for this file.", systemImage: "xmark.rectangle.fill")
            } else {
                ContentUnavailableView("Unable to download file.", systemImage: "xmark.rectangle.fill")
            }
        }.task {
            do {
                self.content = try await fileService.courseFile(
                    for: file,
                    course: course,
                    foldersPath: courseFileVM.traversedFolderIDs,
                    localCopyReceived: { self.content = $0 }
                )
            } catch {
                print("Error fetching file content: \(error)")
            }
        }
    }
}
