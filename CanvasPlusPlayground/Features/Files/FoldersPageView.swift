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


    let course: Course
    @State private var folder: Folder?
    @State private var filesVM: CourseFileViewModel

    @State private var isLoadingContents = true
    @State private var selectedItem: Selection?

    @State private var searchText: String = ""

    @State private var currentSearchTask: Task<Void, Never>?

    init(course: Course, folder: Folder? = nil) {
        self.course = course
        self.folder = folder

        _filesVM = .init(initialValue: CourseFileViewModel(courseID: course.id))
    }

    var body: some View {
        defaultView
            .overlay {
                if searchText.count >= 2 {
                    searchResult
                }
            }
            .refreshable {
                currentSearchTask?.cancel()
                await newQuery()
            }
            .onChange(of: searchText) { _, _ in
                newQueryAsync()
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    }

    private var searchResult: some View {
        SearchResultsListView(dataSource: filesVM) {
            ForEach(filesVM.matchedFiles) { file in
                NavigationLink(
                    value: NavigationModel.Destination.file(file, course.id)
                ) {
                    fileRow(for: file)
                }
                .tag(Selection.file(file))
                .listItemTint(course.rgbColors?.color)
            }
        }
    }

    private var defaultView: some View {
        List(selection: $selectedItem) {
            if !filesVM.displayedFiles.isEmpty {
                Section("Files") {
                    ForEach(filesVM.displayedFiles, id: \.id) { file in
                        NavigationLink(
                            value: NavigationModel.Destination.file(file, course.id)
                        ) {
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
                        NavigationLink(
                            value: NavigationModel.Destination.folder(subFolder, course)
                        ) {
                            folderRow(for: subFolder)
                        }
                        .tag(Selection.folder(subFolder))
                        .listItemTint(course.rgbColors?.color)
                    }
                }
            }
        }
#if os(iOS)
        .onAppear {
            selectedItem = nil
        }
#endif
        .task {
            await loadContents()
        }
        .overlay {
            if !isLoadingContents && filesVM.displayedFiles.isEmpty && filesVM.displayedFolders.isEmpty {
                ContentUnavailableView("This folder is empty.", systemImage: "folder")
            }
        }
        .statusToolbarItem(
            folder?.name ?? "Course Files",
            isVisible: isLoadingContents
        )
        .navigationTitle(folder?.name?.capitalized ?? "Course Files")
        .pickedItem(selectedItem?.pickedValue)
    }

    private func newQuery() async {
        filesVM.page = 1
        filesVM.queryMode = .live
        filesVM.searchText = searchText
        await filesVM.fetchNextPage()
    }

    private func newQueryAsync() {
        currentSearchTask?.cancel()
        currentSearchTask = Task {
            await newQuery()
        }
    }

    @ViewBuilder
    func fileRow(for file: File) -> some View {
        if file.url != nil {
            FileRow(file: file, course: course)
        } else {
            Label("File not available.", systemImage: "document")
                .disabled(true)
        }
    }

    @ViewBuilder
    func folderRow(for subFolder: Folder) -> some View {
        FolderRow(folder: subFolder, course: course)
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

            NewWindowButton(destination: .file(file, course.id))
        }
        .swipeActions(edge: .leading) {
            PinButton(
                itemID: file.id,
                courseID: course.id,
                type: .file
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
    let course: Course

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
        .contextMenu {
            NewWindowButton(destination: .folder(folder, course))
        }
    }

    var count: Int {
        (folder.filesCount ?? 0) + (folder.foldersCount ?? 0)
    }
}
