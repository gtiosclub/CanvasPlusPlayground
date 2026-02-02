//
//  CourseFileManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/8/24.
//

import SwiftUI

@Observable
class CourseFileViewModel: SearchResultListDataSource {

    // MARK: SearchResultListDatasource
    let label: String = "Files"

    var loadingState: LoadingState = .nextPageReady
    var queryMode: PageMode = .live

    func fetchNextPage() async {
        await setLoadingState(.loading)
        do {
            try await fetchFiles()
        } catch {
            await setLoadingState(.error())
        }
    }

    private let courseID: String

    var files = [File]()
    var folders = [Folder]()
    var allFiles = Set<File>()
    var searchText = ""
    var page = 1 // 1-indexed

    var displayedFiles: [File] {
        files.sorted {
            $0.displayName < $1.displayName
        }
    }
    var displayedFolders: [Folder] {
        folders.sorted {
            $0.name ?? "" < $1.name ?? ""
        }
    }

    var matchedFiles: [File] {
        allFiles.filter { file in
            searchText.isEmpty || file.displayName.localizedCaseInsensitiveContains(searchText)
        }
        .sorted { file1, file2 in
            file1.filename < file2.filename
        }
    }

    init(courseID: String) {
        self.courseID = courseID
    }

    func fetchRoot() async -> Folder? {
        if AppEnvironment.isSandbox {
            let rootFolder = SandboxData.dummyRootFolder
            await fetchContent(in: rootFolder)
            return rootFolder
        }
        let request = CanvasRequest.getCourseRootFolder(courseId: courseID)
        if let persistedRootFolder: Folder = try? await CanvasService.shared.load(request)?.first {
            await fetchContent(in: persistedRootFolder)
            return persistedRootFolder
        } else if let rootFolder: Folder = try? await CanvasService.shared.syncWithAPI(request).first {
            await fetchContent(in: rootFolder)
            return rootFolder
        }

        LoggerService.main.error("Failed to fetch root folder.")
        return nil
    }

    func fetchContent(in folder: Folder) async {
        if AppEnvironment.isSandbox {
            self.folders = []
            self.files = SandboxData.dummyFiles
            return
        }
        async let foldersInRootFolder: [Folder] = CanvasService.shared.loadAndSync(
            CanvasRequest.getFoldersInFolder(folderId: folder.id),
            onCacheReceive: { folders in
                self.folders = folders ?? []
            }
        )
        async let filesInRootFolder: [File] = CanvasService.shared.loadAndSync(
            CanvasRequest.getFilesInFolder(folderId: folder.id),
            onCacheReceive: { files in
                self.files = files ?? []
            }
        )

        do {
            let (folders, files) = await ((try foldersInRootFolder), (try filesInRootFolder))

            Task { @MainActor in
                self.folders = folders
                self.files = files
            }
        } catch {
            LoggerService.main.error("\(error.localizedDescription)")
        }
    }

    @MainActor
    func fetchFiles() async throws {
        let request = CanvasRequest.getAllFilesInCourse(
            courseId: courseID,
            searchTerm: searchText.count >= 2 ? searchText : ""
        )

        var files = [File]()

        do {
            switch queryMode {
            case .offline:
                files = (try await CanvasService.shared.load(request, loadingMethod: .page(order: page))) ?? []
            case .live:
                files = try await CanvasService.shared.syncWithAPI(request, loadingMethod: .page(order: page))
            }

            addNewFiles(files)
        } catch {
            // don't make offline query if request was cancelled
            if let error = error as? URLError, error.code == .cancelled { return }

            LoggerService.main.error("Error fetching users:\(error)")

            if queryMode == .live && page == 1 {
                setQueryMode(.offline)
            } else {
                throw error
            }
        }

    }

    @MainActor
    private func addNewFiles(_ newFiles: [File]) {
        if page == 1 {
            LoggerService.main.debug("Users: \(self.allFiles.map(\.displayName))")
            self.allFiles = []
        }

        self.allFiles.formUnion(newFiles)

        if newFiles.isEmpty {
            setLoadingState(.idle) // no more users means no more pages
        } else {
            setLoadingState(.nextPageReady)
            page += 1
        }
    }
}
