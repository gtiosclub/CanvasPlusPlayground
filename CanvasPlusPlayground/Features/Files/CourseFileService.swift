//
//  CourseFileService.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/9/24.
//

import Foundation
#if os(macOS)
import AppKit
#endif

struct CourseFileService {
    static let shared: CourseFileService = .init()

    private static let fileManager: FileManager = .default
    private static var rootURL: URL? {
        if let bundleId = Bundle.main.bundleIdentifier {
            let root = URL.applicationSupportDirectory.appendingPathComponent(bundleId)

            if fileManager.fileExists(atPath: root.path) {
                return root
            } else {
                do {
                    try fileManager.createDirectory(at: root, withIntermediateDirectories: true, attributes: nil)
                    return root
                } catch {
                    print("Failure creating directory to root.")
                    return nil
                }
            }

        } else {
            print("Failure getting bundle identifier")
            return nil
        }
    }
    private static var coursesURL: URL? {
        rootURL?
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

        guard let file else {
            throw FileError.fileWasNil
        }

        let fileURL = try self.pathWithFolders(foldersPath: folderIds, courseId: courseId, fileId: file.id, type: .init(file: file))
        let parentDirURL = fileURL.deletingLastPathComponent()

        try Self.fileManager.createDirectory(
            at: parentDirURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        print("Saving to \(fileURL)")

        do {
            try content.write(to: fileURL, options: .atomic)

            file.localURL = fileURL
        } catch {
            print("Writing failed due to \(error)")
            throw FileError.fileWriteFailed
        }

        return fileURL
    }

    @discardableResult
    func setLocationForCourseFile(
        _ file: File,
        course: Course,
        foldersPath: [String]
    ) -> URL? {
        print("Checking if \(file.displayName) exists")
        let fileLoc = try? pathWithFolders(foldersPath: foldersPath, courseId: course.id, fileId: file.id, type: FileType(file: file))

        if let fileLoc, Self.fileManager
            .fileExists(atPath: fileLoc.path(percentEncoded: false)) {
            print("File exists locally!\n")

            if fileLoc != file.localURL {
                print("Updating File's localURL")
                file.localURL = fileLoc
            }

            return fileLoc
        } else if file.localURL != nil {
            print("Updating File's localURL to nil since it no longer exists locally")
            file.localURL = nil
        }

        print("File does not exist locally\n")

        return nil
    }

    func courseFile(
        for file: File,
        course: Course,
        foldersPath: [String],
        localCopyReceived: (Data?, URL) -> Void
    ) async throws -> (Data, URL) {
        // Provide local copy meanwhile
        if let fileLoc = self.setLocationForCourseFile(file, course: course, foldersPath: foldersPath),
           let data = try? Data(contentsOf: fileLoc) {
            localCopyReceived(data, fileLoc)
        }

        // Start downloading remote version
        if let urlStr = file.url, let url = URL(string: urlStr) {
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

                return (content, url)
            } catch {
                print("Failed to save file. \(error)")
                throw error
            }

        } else {
            throw URLError(.badURL)
        }
    }

    // MARK: Global

    static func clearAllFiles() throws {
        guard let fileURL = coursesURL else {
            throw FileError.directoryInaccessible
        }

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: nil)

            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
                print("Deleted: \(fileURL.lastPathComponent)")
            }

            print("All files in \(fileURL.path) have been deleted.")

        } catch {
            print("Error deleting files: \(error.localizedDescription)")
        }
    }

    /// Opens finder tab at specific directory URL
    static func showInFinder(fileURL: URL = rootURL ?? .currentDirectory()) {
        #if os(macOS)
        NSWorkspace.shared.open(fileURL)
        #endif
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

    private func pathWithFolders(foldersPath: [String], courseId: String, fileId: String, type: FileType?) throws -> URL {
        guard let coursesURL = Self.coursesURL else {
            throw FileError.directoryInaccessible
        }

        var pathURL = coursesURL
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
    case fileWriteFailed, fileWasNil, directoryInaccessible

    var message: String {
        switch self {
        case .fileWriteFailed:
            return "File save failed"
        case .fileWasNil:
            return "File was nil"
        case .directoryInaccessible:
            return "Directory inaccessible"
        }
    }

    var description: String {
        message
    }
}
