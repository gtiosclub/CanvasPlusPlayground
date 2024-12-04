//
//  CourseFilesView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/7/24.
//

import SwiftUI

struct CourseFilesView: View {
    let course: Course
    let folder: Folder?
    @State private var fileManager: CourseFileManager

    init(course: Course, folder: Folder? = nil) {
        self.course = course
        self.folder = folder
        _fileManager = .init(initialValue: CourseFileManager(courseID: course.id))
    }

    var body: some View {
        NavigationStack {
            
            List {
                Section("Files") {
                    ForEach(fileManager.displayedFiles, id: \.id) { file in
                        FileRow(for: file)
                    }
                }
            
                
                Section("Folders") {
                    ForEach(fileManager.displayedFolders, id: \.id) { subFolder in
                        FolderRow(for: subFolder)
                    }
                }
                
            }
            .task {
                if let folder {
                    await fileManager.fetchContent(in: folder)
                } else {
                    await fileManager.fetchRoot()
                }
            }
            .navigationTitle("Files")

        }
    }
    
    @ViewBuilder
    func FileRow(for file: File) -> some View {
        if let url = file.url, let url = URL(string: url)  {
            NavigationLink(destination: CoursePDFView(url: url)) {
                Label(file.displayName ?? "Couldn't find file name.", systemImage: "document")
            }
        } else {
            Label("File not available.", systemImage: "document")
        }
    }
    
    @ViewBuilder
    func FolderRow(for subFolder: Folder) -> some View {
        NavigationLink(destination: CourseFilesView(course: course, folder: subFolder)) {
            Label(subFolder.name ?? "Couldn't find folder name.", systemImage: "folder")
        }
    }
}
