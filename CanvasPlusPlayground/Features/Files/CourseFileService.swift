//
//  CourseFileService.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/9/24.
//

import Foundation

struct CourseFileService {
    
    private static let fileManager: FileManager = .default
    private static var documentsURL: URL {
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
        weak var file = file
        
        guard let file, let type = FileType.fromFile(file) else {
            throw FileError.unsuppportedFileType
        }
        
        let fileURL = self.pathWithFolders(foldersPath: folderIds, courseId: courseId, fileId: file.id, type: type)
        let parentDirURL = fileURL.deletingLastPathComponent()
                
        try Self.fileManager.createDirectory(
            at: parentDirURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        print("Saving to \(fileURL)")
        
        do {
            try content.write(to: fileURL, options: .atomic)
        } catch {
            print("Writing failed due to \(error)")
            throw FileError.fileWriteFailed
        }
        
        return fileURL
    }
    
    func courseFile(
        for file: File,
        course: Course,
        foldersPath: [String],
        localCopyReceived: (Data?) -> Void,
        remoteFileReceived: @escaping (Data?) -> Void
    ) throws {
        let fileLoc = pathWithFolders(foldersPath: foldersPath, courseId: course.id, fileId: file.id, type: FileType.fromFile(file))
        
        // Start downloading remote version
        if let urlStr = file.url, let url = URL(string: urlStr)  {
            print("File doesn't exist! Downloading ...")
            
            self.downloadFile(from: url) { [weak file] localURL in
                if let localURL, let content = try? Data(contentsOf: localURL) {
                    remoteFileReceived(content)
                    
                    if let file, let url = try? self.saveCourseFile(courseId: course.id, folderIds: foldersPath, file: file, content: content) {
                        print("File successfully saved at \(url.path())")
                    } else {
                        print("Failed to save file.")
                    }
                } else {
                    print("Error fetching file content from remote.")
                }
            }
        } else {
            remoteFileReceived(nil)
        }
        
        // Provide local copy meanwhile
        if Self.fileManager.fileExists(atPath: fileLoc.path()), let data = try? Data(contentsOf: fileLoc) {
            localCopyReceived(data)
        }
        
    }
    
    static func clearAllFiles() throws {
        let documentURLs = documentsURL

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentURLs, includingPropertiesForKeys: nil)
            
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
                print("Deleted: \(fileURL.lastPathComponent)")
            }
            
            print("All files in \(documentURLs.path) have been deleted.")
            
        } catch {
            print("Error deleting files: \(error.localizedDescription)")
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
    
    private func pathWithFolders(foldersPath: [String], courseId: String, fileId: String, type: FileType?) -> URL {
        var pathURL = Self.documentsURL
            .appendingPathComponent(courseId)
            .appendingPathComponent("files")
        for folderId in foldersPath {
            pathURL.appendPathComponent(folderId)
        }
        pathURL.appendPathComponent(fileId + (type?.formatExtension ?? ""))
        
        return pathURL
    }
}


enum FileError: Error {
    case unsuppportedFileType, fileWriteFailed
    
    var message: String {
        switch self {
        case .unsuppportedFileType:
            return "Unsupported file type"
        case .fileWriteFailed:
            return "File save failed"
        }
    }
}
