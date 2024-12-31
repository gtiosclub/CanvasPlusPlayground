//
//  CourseFileManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/8/24.
//

import SwiftUI

@Observable
class CourseFileManager {
    private let courseID: String
    var files = [File]()
    var folders = [Folder]()

    var displayedFiles: [File] {
        files.sorted {
            $0.displayName ?? "" < $1.displayName ?? ""
        }
    }
    var displayedFolders: [Folder] {
        folders.sorted {
            $0.name ?? "" < $1.name ?? ""
        }
    }

    init(courseID: String) {
        self.courseID = courseID
    }

    func fetchRoot() async {

        if let persistedRootFolder: Folder = try? await CanvasService.shared.load(.getCourseRootFolder(courseId: courseID))?.first {
            await fetchContent(in: persistedRootFolder)
        } else if let rootFolder: Folder = try? await CanvasService.shared.syncWithAPI(.getCourseRootFolder(courseId: courseID)).first {
            await fetchContent(in: rootFolder)
        } else {
            print("Failed to fetch root folder.")
        }

    }

    func fetchContent(in folder: Folder) async {

        async let foldersInRootFolder: [Folder] = CanvasService.shared.loadAndSync(.getFoldersInFolder(folderId: folder.id), onCacheReceive: { folders in
            self.folders = folders ?? []
        })
        async let filesInRootFolder: [File] = CanvasService.shared.loadAndSync(.getFilesInFolder(folderId: folder.id), onCacheReceive: { files in
            self.files = files ?? []
        })

        let (folders, files) = await ((try? foldersInRootFolder), (try? filesInRootFolder))

        if let folders {
            self.folders = folders
        }
        if let files {
            self.files = files
        }
    }
}
