//
//  CourseFileService.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/9/24.
//

import Foundation

struct CourseFileService {
    
    private let fileManager: FileManager = .default
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(StorageKeys.accessTokenValue)
            .appendingPathComponent("courses")
    }
    
    
    func saveCourseFile(
        courseId: String,
        folderIds: [String],
        file: File,
        content: Data
    ) throws -> URL {
        guard FileType.isSupported(file) else {
            throw FileError.unsuppportedFileType
        }
        
        var pathURL = self.pathWithFolders(foldersPath: folderIds, courseId: courseId, fileId: file.id)
                
        try fileManager.createDirectory(
            at: pathURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        try content.write(to: pathURL)
        
        return pathURL
    }
    
    func courseFile(
        for file: File,
        course: Course,
        foldersPath: [String],
        localCopyReceived: (Data?) -> Void,
        remoteFileReceived: @escaping (Data?) -> Void
    ) throws {
        let fileLoc = pathWithFolders(foldersPath: foldersPath, courseId: course.id, fileId: file.id)
        
        // Start downloading remote version
        if let urlStr = file.url, let url = URL(string: urlStr)  {
            print("File doesn't exist! Downloading ...")
            
            self.downloadFile(from: url) { localURL in
                if let localURL, let content = try? Data(contentsOf: localURL) {
                    remoteFileReceived(content)
                    
                    if let url = try? self.saveCourseFile(courseId: course.id, folderIds: foldersPath, file: file, content: content) {
                        print("File successfully saved at \(url.path())")
                    } else {
                        print("Failed to save file at \(url.path())")
                    }
                } else {
                    print("Error fetching file content from remote.")
                }
            }
        } else {
            remoteFileReceived(nil)
        }
        
        // Provide local copy meanwhile
        if fileManager.fileExists(atPath: fileLoc.path()), let data = try? Data(contentsOf: fileLoc) {
            localCopyReceived(data)
        }
        
    }
    
    // MARK: Helpers
    
    private func downloadFile(
        from remoteURL: URL,
        completion: @escaping (URL?) -> Void
    ) {
        let task = URLSession.shared.downloadTask(with: remoteURL) { tempUrl, _, error in
            if let error {
                completion(nil)
                print("Error downloading file: \(error)")
                return
            }
            
            guard let tempUrl else {
                completion(nil)
                print("Temp URL for file is nil.")
                return
            }
            
            completion(tempUrl)
        }
        task.resume()
    }
    
    private func pathWithFolders(foldersPath: [String], courseId: String, fileId: String) -> URL {
        var pathURL = documentsURL
            .appendingPathComponent(courseId)
            .appendingPathComponent("files")
        for folderId in foldersPath {
            pathURL.appendPathComponent(folderId)
        }
        pathURL.appendPathComponent(fileId)
        
        return pathURL
    }
}


enum FileError: Error {
    case unsuppportedFileType
    
    var message: String {
        switch self {
        case .unsuppportedFileType:
            return "Unsupported file type"
        }
    }
}
