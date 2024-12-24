//
//  FoldersPageView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/10/24.
//

import SwiftUI

struct FoldersPageView: View {
    let course: Course
    @State var folder: Folder?
    @State private var filesVM: CourseFileViewModel

    @State private var isLoadingContents = true

    init(course: Course, folder: Folder? = nil, traversedFolderIDs: [String] = []) {
        self.course = course
        self.folder = folder
        
        _filesVM = .init(initialValue: CourseFileViewModel(courseID: course.id, traversedFolderIDs: traversedFolderIDs))
    }
    
    var body: some View {
        List {
            Section("Files") {
                ForEach(filesVM.displayedFiles, id: \.id) { file in
                    FileRow(for: file)
                        .listItemTint(course.rgbColors?.color)
                }
            }
        
            
            Section("Folders") {
                ForEach(filesVM.displayedFolders, id: \.id) { subFolder in
                    FolderRow(for: subFolder)
                        .listItemTint(course.rgbColors?.color)
                }
            }
            
        }
        .task {
            await loadContents()
        }
        .statusToolbarItem(
            folder?.name ?? "Files",
            isVisible: isLoadingContents
        )
        .navigationTitle("Files")
    }
    
    @ViewBuilder
    func FileRow(for file: File) -> some View {
        if file.url != nil  {
            NavigationLink(destination: destination(for: file)) {
                Label(file.displayName, systemImage: "document")
            }
        } else {
            Label("File not available.", systemImage: "document")
        }
    }
    
    func destination(for file: File) -> some View {
        FileViewer(course: course, file: file)
            .environment(filesVM)
    }
    
    @ViewBuilder
    func FolderRow(for subFolder: Folder) -> some View {
        NavigationLink(destination: FoldersPageView(course: course, folder: subFolder, traversedFolderIDs: filesVM.traversedFolderIDs)) {
            Label(subFolder.name ?? "Couldn't find folder name.", systemImage: "folder")
        }
    }

    private func loadContents() async {
        isLoadingContents = true
        if let folder {
            await filesVM.fetchContent(in: folder)
        } else {
            self.folder = await filesVM.fetchRoot()
        }
        isLoadingContents = false
    }
}
