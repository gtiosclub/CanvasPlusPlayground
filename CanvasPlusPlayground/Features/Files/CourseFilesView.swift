//
//  CourseFilesView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/7/24.
//

import SwiftUI

struct CourseFilesView: View {
    let course: Course
    @State var folder: Folder?
    @State private var filesVM: CourseFileViewModel

    init(course: Course, folder: Folder? = nil, prevFilesVM: CourseFileViewModel? = nil) {
        self.course = course
        self.folder = folder
        
        if let prevFilesVM {
            _filesVM = .init(initialValue: CourseFileViewModel(courseID: course.id, traversedFolderIDs: prevFilesVM.traversedFolderIDs))
        } else {
            _filesVM = .init(initialValue: CourseFileViewModel(courseID: course.id, traversedFolderIDs: []))
        }
    }

    var body: some View {
        NavigationStack {
            
            List {
                Section("Files") {
                    ForEach(filesVM.displayedFiles, id: \.id) { file in
                        FileRow(for: file)
                    }
                }
            
                
                Section("Folders") {
                    ForEach(filesVM.displayedFolders, id: \.id) { subFolder in
                        FolderRow(for: subFolder)
                    }
                }
                
            }
            .task {
                if let folder {
                    await filesVM.fetchContent(in: folder)
                } else {
                    self.folder = await filesVM.fetchRoot()
                }
            }
            .navigationTitle("Files")
            .onAppear {
                if let folderId = folder?.id {
                    filesVM.traversedFolderIDs.append(folderId)
                }
            }
            .onDisappear {
                print("Back to \(folder?.name ?? "non-folder")")
                if !filesVM.traversedFolderIDs.isEmpty { filesVM.traversedFolderIDs.removeLast() }
            }

        }
    }
    
    @ViewBuilder
    func FileRow(for file: File) -> some View {
        if file.url != nil  {
            NavigationLink(destination: destination(for: file)) {

                Label(file.displayName ?? "Couldn't find file name.", systemImage: "document")
            }
        } else {
            Label("File not available.", systemImage: "document")
        }
    }
    
    @ViewBuilder
    func destination(for file: File) -> some View {
        FileViewer(course: course, file: file, courseFileVM: filesVM)
    }
    
    @ViewBuilder
    func FolderRow(for subFolder: Folder) -> some View {
        NavigationLink(destination: CourseFilesView(course: course, folder: subFolder)) {
            Label(subFolder.name ?? "Couldn't find folder name.", systemImage: "folder")
        }
    }
}
