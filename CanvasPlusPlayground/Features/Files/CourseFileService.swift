//
//  CourseFileService.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/9/24.
//

import Foundation
import AppKit

struct CourseFileService {
    
    private static let fileManager: FileManager = .default
    private static var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    private static var coursesURL: URL {
        documentsURL
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
            throw FileError.unsupportedFileType
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
        localCopyReceived: (Data?) -> Void
    ) async throws -> Data {
        let fileLoc = pathWithFolders(foldersPath: foldersPath, courseId: course.id, fileId: file.id, type: FileType.fromFile(file))
        
        // Provide local copy meanwhile
        if Self.fileManager.fileExists(atPath: fileLoc.path()), let data = try? Data(contentsOf: fileLoc) {
            localCopyReceived(data)
        }
        
        // Start downloading remote version
        if let urlStr = file.url, let url = URL(string: urlStr)  {
            print("File doesn't exist! Downloading ...")
            
            weak var file = file
            let tempFileLoc = try await self.downloadFile(from: url)
            
            let content = try Data(contentsOf: tempFileLoc)
            
            do {
                guard let file else {
                    throw FileError.fileWasNil
                }
                let url = try self.saveCourseFile(courseId: course.id, folderIds: foldersPath, file: file, content: content)
                print("File successfully saved at \(url.path())")
            } catch {
                print("Failed to save file. \(error)")
            }
            
            return content
            
        } else {
            throw URLError(.badURL)
        }
    }
    
    // MARK: Global
    
    static func clearAllFiles() throws {
        let documentURLs = coursesURL

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
    
    /// Opens finder tab at specific directory URL
    static func showInFinder(fileURL: URL = documentsURL) {
        NSWorkspace.shared.open(fileURL)
    }
    
    // MARK: Helpers
    
    private func downloadFile(
        from remoteURL: URL
    ) async throws -> URL {
        let (tempUrl, response) = try await URLSession.shared.download(from: remoteURL)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Error downloading file: \(response)")
            throw URLError(.badServerResponse)
        }
        
        return tempUrl
    }
    
    private func pathWithFolders(foldersPath: [String], courseId: String, fileId: String, type: FileType?) -> URL {
        var pathURL = Self.coursesURL
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
    case unsupportedFileType, fileWriteFailed, fileWasNil
    
    var message: String {
        switch self {
        case .unsupportedFileType:
            return "Unsupported file type"
        case .fileWriteFailed:
            return "File save failed"
        case .fileWasNil:
            return "File was nil"
        }
    }
    
    var description: String {
        message
    }
}
