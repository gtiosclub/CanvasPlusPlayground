//
//  FoldersPageView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/10/24.
//

import SwiftUI

struct FoldersPageView: View {
    enum Selection: Hashable, Identifiable {
        case file(File)
        case folder(Folder)

        var id: String {
            switch self {
            case .file(let file):
                return file.id
            case .folder(let folder):
                return folder.id
            }
        }

        var pickedValue: File? {
            if case .file(let file) = self {
                return file
            } else {
                return nil
            }
        }
    }

    @Namespace private var namespace

    let course: Course
    @State private var folder: Folder?
    @State private var filesVM: CourseFileViewModel

    @State private var isLoadingContents = true
    @State private var selectedItem: Selection?

    init(course: Course, folder: Folder? = nil, traversedFolderIDs: [String] = []) {
        self.course = course
        self.folder = folder

        _filesVM = .init(initialValue: CourseFileViewModel(courseID: course.id, traversedFolderIDs: traversedFolderIDs))
    }

    var body: some View {
        List(selection: $selectedItem) {
            if !filesVM.displayedFiles.isEmpty {
                Section("Files") {
                    ForEach(filesVM.displayedFiles, id: \.id) { file in
                        NavigationLink(value: Selection.file(file)) {
                            fileRow(for: file)
                        }
                        .tag(Selection.file(file))
                        .listItemTint(course.rgbColors?.color)
                    }
                }
            }

            if !filesVM.displayedFolders.isEmpty {
                Section("Folders") {
                    ForEach(filesVM.displayedFolders, id: \.id) { subFolder in
                        NavigationLink(value: Selection.folder(subFolder)) {
                            folderRow(for: subFolder)
                        }
                        .tag(Selection.folder(subFolder))
                        .listItemTint(course.rgbColors?.color)
                    }
                }
            }
        }
        .task {
            await loadContents()
        }
        #if os(iOS)
        .navigationDestination(item: $selectedItem) { item in
            if #available(iOS 18.0, *) {
                destinationView(for: item)
                    #if os(iOS)
                    .navigationTransition(.zoom(sourceID: item.id, in: namespace))
                    #endif
            } else {
                destinationView(for: item)
            }
        }
        #else
        .navigationDestination(for: Selection.self) { item in
            if #available(iOS 18.0, *) {
                destinationView(for: item)
                    #if os(iOS)
                    .navigationTransition(.zoom(sourceID: item.id, in: namespace))
                    #endif
            } else {
                destinationView(for: item)
            }
        }
        #endif
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
        .pickedItem(selectedItem?.pickedValue)
    }

    @ViewBuilder
    func fileRow(for file: File) -> some View {
        if file.url != nil {
            Group {
                if #available(iOS 18.0, *) {
                    FileRow(file: file, course: course)
                        #if os(iOS)
                        .matchedTransitionSource(id: file.id, in: namespace)
                        #endif
                } else {
                    FileRow(file: file, course: course)
                }
            }
            .environment(filesVM)
        } else {
            Label("File not available.", systemImage: "document")
        }
    }

    @ViewBuilder
    func folderRow(for subFolder: Folder) -> some View {
        NavigationLink(value: subFolder) {
            FolderRow(folder: subFolder)
        }
    }

    @ViewBuilder
    func destinationView(for item: Selection) -> some View {
        switch item {
        case .file(let file):
            FileViewer(course: course, file: file)
                .environment(filesVM)
        case .folder(let folder):
            FoldersPageView(course: course, folder: folder, traversedFolderIDs: filesVM.traversedFolderIDs)
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

private struct FileRow: View {
    @Environment(CourseFileViewModel.self) private var filesVM
    let file: File
    let course: Course

    var body: some View {
        HStack {
            mainContent

            Spacer()

            if file.localURL == nil {
                Image(systemName: "arrow.down.circle.dotted")
            }
        }
        .imageScale(.large)
        .contextMenu {
            PinButton(
                itemID: file.id,
                courseID: course.id,
                type: .file
            )
        }
        .swipeActions(edge: .leading) {
            PinButton(
                itemID: file.id,
                courseID: course.id,
                type: .file
            )
        }
        .onAppear {
            // Updates file.localURL if needed
            CourseFileService.shared
                .setLocationForCourseFile(
                    file,
                    course: course,
                    foldersPath: filesVM.traversedFolderIDs
                )
        }
    }

    private var mainContent: some View {
        HStack {
            Image(systemName: "document")
                .foregroundStyle(.tint)

            VStack(alignment: .leading) {
                Text(file.displayName)
                    .font(.headline)

                if let size = file.size {
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
