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

    init(courseID: String) {
        self.courseID = courseID
    }

    func fetchRoot() async {
        guard let rootFolder: Folder = try? await CanvasService.shared.loadAndSync(.getCourseRootFolder(courseId: courseID))[0] else {
            print("Failed to fetch root folder.")
            return
        }
        
        await fetchContent(in: rootFolder)
    }
    
    func fetchContent(in folder: Folder) async {
        
        async let foldersInRootFolder: [Folder] = CanvasService.shared.loadAndSync(.getFoldersInFolder(folderId: folder.id))
        async let filesInRootFolder: [File] = CanvasService.shared.loadAndSync(.getFilesInFolder(folderId: folder.id))
        
        let (folders, files) = await ((try? foldersInRootFolder) ?? [], (try? filesInRootFolder) ?? [])
        
        self.folders = folders
        self.files = files
    }
}
