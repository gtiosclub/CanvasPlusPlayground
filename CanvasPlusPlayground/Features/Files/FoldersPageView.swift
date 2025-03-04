//
//  FoldersPageView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/10/24.
//

import SwiftData
import SwiftUI

struct FoldersPageView: View {
    @Namespace private var namespace

    let course: Course
    @State private var folder: Folder?
    @State private var filesVM: CourseFileViewModel

    @State private var isLoadingContents = true
    @State private var selectedFile: File?

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
                try? await DownloadService.shared.createDownload(for: selectedFile, course: course, folderIds: [])
            }

            selectedFile = nil
        }
//        #if os(iOS)
//        .fullScreenCover(item: $selectedFile) { file in
//            Group {
//                if #available(iOS 18.0, *) {
//                    NavigationStack {
//                        FileViewer(course: course, file: file)
//                    }
//                    .navigationTransition(.zoom(sourceID: file.id, in: namespace))
//                } else {
//                    NavigationStack {
//                        FileViewer(course: course, file: file)
//                    }
//                }
//            }
//            .environment(filesVM)
//        }
//        #else
//        .navigationDestination(item: $selectedFile) { file in
//            FileViewer(course: course, file: file)
//                .environment(filesVM)
//        }
//        #endif
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

@Observable
class DownloadButtonViewModel {
    var download: Download?

    init(download: Download?) {
        self.download = download
    }
}

struct DownloadButtonView: View {
    let model: DownloadButtonViewModel

    var body: some View {
        DownloadIcon(progress: model.download?.progress, completed: model.download?.localURL != nil)
    }
}

struct DownloadIcon: View {
    var progress: Double?
    var completed: Bool

    var size: CGFloat = 26.0

    var body: some View {
        ProgressView(value: progress, total: 1.0)
            .progressViewStyle(GaugeProgressStyle(strokeWidth: 2.0))
            .overlay {
                Image(systemName: "arrow.down")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .offset(x: 0, y: progress == nil ? 0 : size)
                    .opacity(progress == nil ? 1 : 0)
                    .foregroundStyle(.secondary)
            }
            .overlay {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.4, weight: .bold))
                    .offset(x: 0, y: progress == 1 ? 0 : size)
                    .opacity(progress == 1 ? 1 : 0)
                    .foregroundColor(.white)
            }
            .clipShape(Circle())
            .animation(.default, value: completed)
            .animation(.default, value: progress)
            .frame(width: size, height: size)
            .font(.system(size: size, weight: .bold))
    }

    struct GaugeProgressStyle: ProgressViewStyle {
        var strokeColor = Color.accentColor
        var strokeWidth = 2.5

        func makeBody(configuration: Configuration) -> some View {
            let fractionCompleted = configuration.fractionCompleted

            return Circle()
                .trim(from: 0, to: fractionCompleted ?? 0.0)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .overlay {
                    if fractionCompleted == 1.0 {
                        Circle()
                            .fill(strokeColor)
                    }
                }
                .background {
                    if fractionCompleted == nil {
                        Circle()
                            .stroke(.secondary, style: .init(lineWidth: strokeWidth, lineCap: .butt, lineJoin: .round, dash: [2], dashPhase: 1))
                    }
                }
                .background {
                    if fractionCompleted != nil {
                        Circle()
                            .stroke(.secondary, lineWidth: strokeWidth)
                    }
                }
                .padding(strokeWidth)
                .animation(.default, value: fractionCompleted)
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
