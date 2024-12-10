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

    @State var courseFileVM: CourseFileViewModel
    @State var content: Data?
    
    var fileType: FileType? {
        FileType.fromFile(file)
    }
    
    init(course: Course, file: File, courseFileVM: CourseFileViewModel) {
        self.course = course
        self.file = file
        self.courseFileVM = courseFileVM
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
                    CoursePDFView(source: .data(content)) // TODO: Modify PDF viewer to take data
                }
            } else if content != nil {
                ContentUnavailableView("Preview not supported for this file.", image: "x.fill")
            } else {
                ContentUnavailableView("Unable to download file.", image: "x.fill")
            }
        }.task {
            do {
                try fileService.courseFile(
                    for: file,
                    course: course,
                    foldersPath: courseFileVM.traversedFolderIDs,
                    localCopyReceived: { self.content = $0 },
                    remoteFileReceived: { self.content = $0 })
            } catch {
                print("Error fetching file content: \(error)")
            }
        }
    }
}
