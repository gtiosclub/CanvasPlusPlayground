//
//  FoldersPageView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/10/24.
//

import QuickLook
import SwiftData
import SwiftUI

struct FoldersPageView: View {
    @Namespace private var namespace

    let course: Course
    @State private var folder: Folder?
    @State private var filesVM: CourseFileViewModel

    @State private var isLoadingContents = true
    @State private var selectedFile: File?
    @State private var url: URL?

    @Environment(\.modelContext) var modelContext

    init(course: Course, folder: Folder? = nil, traversedFolderIDs: [String] = []) {
        self.course = course
        self.folder = folder

        _filesVM = .init(initialValue: CourseFileViewModel(courseID: course.id, traversedFolderIDs: traversedFolderIDs))
    }

    var body: some View {
        List(selection: $selectedFile) {
            if !filesVM.displayedFiles.isEmpty {
                Section("Files") {
                    ForEach(filesVM.displayedFiles, id: \.id) { file in
                        fileRow(for: file)
                            .tag(file)
                            .listItemTint(course.rgbColors?.color)
                    }
                }
            }

            if !filesVM.displayedFolders.isEmpty {
                Section("Folders") {
                    ForEach(filesVM.displayedFolders, id: \.id) { subFolder in
                        folderRow(for: subFolder)
                            .listItemTint(course.rgbColors?.color)
                    }
                }
            }
        }
        .task {
            await loadContents()
        }
        .task(id: selectedFile) {
            if let selectedFile {
                if let download = selectedFile.download, download.localURL != nil {
                    url = download.localURL!
                } else {
                    try? await DownloadService.shared.createDownload(for: selectedFile, course: course, folderIds: [])
                }
            }

            selectedFile = nil
        }
        .quickLookPreview($url)
        .overlay {
            if !isLoadingContents && filesVM.displayedFiles.isEmpty && filesVM.displayedFolders.isEmpty {
                ContentUnavailableView("This folder is empty.", systemImage: "folder")
            }
        }
        .statusToolbarItem(
            folder?.name ?? "Files",
            isVisible: isLoadingContents
        )
        .navigationTitle(folder?.name?.capitalized ?? "Files")
    }

    @ViewBuilder
    func fileRow(for file: File) -> some View {
        if file.url != nil {
            Group {
                if #available(iOS 18.0, *) {
                    FileRow(model: .init(file: file, course: course))
                        #if os(iOS)
                        .matchedTransitionSource(id: file.id, in: namespace)
                        #endif
                } else {
                    FileRow(model: .init(file: file, course: course))
                }
            }
            .environment(filesVM)
        } else {
            Label("File not available.", systemImage: "document")
        }
    }

    @ViewBuilder
    func folderRow(for subFolder: Folder) -> some View {
        NavigationLink(destination: FoldersPageView(course: course, folder: subFolder, traversedFolderIDs: filesVM.traversedFolderIDs)) {
            FolderRow(folder: subFolder)
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

@Observable
class FileRowViewModel {
    var file: File
    var course: Course

    init(file: File, course: Course) {
        self.file = file
        self.course = course
    }
}

struct FileRow: View {
    let model: FileRowViewModel

    var body: some View {
        HStack {
            mainContent

            Spacer()

            DownloadButtonView(model: .init(download: model.file.download))
        }
        .contextMenu {
            PinButton(
                itemID: model.file.id,
                courseID: model.course.id,
                type: .file
            )
        }
        .swipeActions(edge: .leading) {
            PinButton(
                itemID: model.file.id,
                courseID: model.course.id,
                type: .file
            )
        }
    }

    private var mainContent: some View {
        HStack {
            Image(systemName: "document")
                .foregroundStyle(.tint)

            VStack(alignment: .leading) {
                Text(model.file.displayName)
                    .font(.headline)

                if let size = model.file.size {
                    Text(size.formatted(.byteCount(style: .file)))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct FolderRow: View {
    let folder: Folder

    var body: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundStyle(.tint)

            VStack(alignment: .leading) {
                Text(folder.name ?? "Unknown Folder")
                    .font(.headline)

                Text("\(count) items")
                    .foregroundStyle(.secondary)
            }
        }
        .imageScale(.large)
    }

    var count: Int {
        (folder.filesCount ?? 0) + (folder.foldersCount ?? 0)
    }
}
