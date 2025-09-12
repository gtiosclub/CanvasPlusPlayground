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
        //MARK: placeholder for future implementation as the VM currently doesn't make network call for searching
    }

    private let courseID: String

    var files = [File]()
    var folders = [Folder]()
    var allFiles = [File]()
    var searchText = ""

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
            let matchesSearchText = searchText.isEmpty || file.displayName.localizedCaseInsensitiveContains(searchText)
            return matchesSearchText
        }
        .sorted { file1, file2 in
            file1.filename < file2.filename
        }
    }

    init(courseID: String) {
        self.courseID = courseID
    }

    /// added isForSearching as the parameter that when set to true prevents the function from calling fetchContent(:)
    /// because in the case of searching, we only need to get the root folder object which then gets called on in traverseAndCollectFiles(:)
    func fetchRoot(isForSearching: Bool = false) async -> Folder? {
        let request = CanvasRequest.getCourseRootFolder(courseId: courseID)
        if let persistedRootFolder: Folder = try? await CanvasService.shared.load(request)?.first {
            await fetchContent(in: persistedRootFolder)
            if !isForSearching {
                await fetchContent(in: persistedRootFolder)
            }
            return persistedRootFolder
        } else if let rootFolder: Folder = try? await CanvasService.shared.syncWithAPI(request).first {
            await fetchContent(in: rootFolder)
            if !isForSearching {
                await fetchContent(in: rootFolder)
            }
            return rootFolder
        }

        LoggerService.main.error("Failed to fetch root folder.")
        return nil
    }

    func fetchContent(in folder: Folder) async {
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
}

// MARK: Collapse all Folders into a flat array of Files
extension CourseFileViewModel {

    func getAllFiles() async  {
        guard let root = await fetchRoot(isForSearching: true) else { return }
        allFiles = await traverseAndCollectFiles(from: root)
    }

    /// recursively traverses the files tree and collect all files from each folder
    private func traverseAndCollectFiles(from folder: Folder) async -> [File] {
        let (files, subFolders) = await loadContents(of: folder)
        var all = files

        await withTaskGroup(of: [File].self) { group in
            for subFolder in subFolders {
                group.addTask { [self] in
                    await self.traverseAndCollectFiles(from: subFolder)
                }
            }

            for await subFiles in group {
                all.append(contentsOf: subFiles)
            }
        }

        return all
    }

    /// a non-mutating version of fetchContent(:) to avoid driving unwanted UI updates
    func loadContents(of folder: Folder) async -> (files: [File], folders: [Folder]) {
        async let foldersTask: [Folder] = CanvasService.shared.loadAndSync(
            CanvasRequest.getFoldersInFolder(folderId: folder.id),
            onCacheReceive: { _ in }
        )
        async let filesTask: [File] = CanvasService.shared.loadAndSync(
            CanvasRequest.getFilesInFolder(folderId: folder.id),
            onCacheReceive: { _ in }
        )

        do {
            let (folders, files) = await ((try foldersTask), (try filesTask))
            return (files, folders)
        } catch {
            LoggerService.main.error("\(error.localizedDescription)")
            return ([], [])
        }
    }
}
