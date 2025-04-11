//
//  CourseFileService.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/9/24.
//

import Foundation
import PDFKit
#if os(macOS)
import AppKit
#endif

struct CourseFileService {
    static let shared: CourseFileService = .init()

    private static let fileManager: FileManager = .default

    private static var rootURL: URL? {
        URL.appRootURL
    }

    private static var coursesURL: URL? {
        rootURL?
            .appendingPathComponent(StorageKeys.accessTokenValue)
            .appendingPathComponent("courses")
    }

    func saveCourseFile(
        courseId: String,
        file: File,
        content: Data
    ) throws -> URL {
        weak var file = file

        guard let file else {
            throw FileError.fileWasNil
        }

        let fileURL = try self.destinationPath(courseId: courseId, fileId: file.id, type: .init(file: file))
        let parentDirURL = fileURL.deletingLastPathComponent()

        try Self.fileManager.createDirectory(
            at: parentDirURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        LoggerService.main.debug("Saving to \(fileURL)")

        do {
            try content.write(to: fileURL, options: .atomic)

            file.localURL = fileURL
        } catch {
            LoggerService.main.error("Writing failed due to \(error)")
            throw FileError.fileWriteFailed
        }

        return fileURL
    }

    @discardableResult
    func setLocationForCourseFile(
        _ file: File,
        courseID: Course.ID
    ) -> URL? {
        LoggerService.main.debug("Checking if \(file.displayName) exists")

        let fileLoc = try? destinationPath(courseId: courseID, fileId: file.id, type: FileType(file: file))

        if let fileLoc, Self.fileManager
            .fileExists(atPath: fileLoc.path(percentEncoded: false)) {
            LoggerService.main.debug("File exists locally!\n")

            if fileLoc != file.localURL {
                LoggerService.main.debug("Updating File's localURL")
                file.localURL = fileLoc
            }

            return fileLoc
        } else if file.localURL != nil {
            LoggerService.main.debug("Updating File's localURL to nil since it no longer exists locally")
            file.localURL = nil
        }

        LoggerService.main.debug("File does not exist locally")

        return nil
    }

    func courseFile(
        for file: File,
        courseID: Course.ID,
        localCopyReceived: (Data?, URL) -> Void
    ) async throws -> (Data, URL) {
        // Provide local copy meanwhile
        if let fileLoc = self.setLocationForCourseFile(file, courseID: courseID),
           let data = try? Data(contentsOf: fileLoc) {
            localCopyReceived(data, fileLoc)
        }

        // Start downloading remote version
        if let urlStr = file.url, let url = URL(string: urlStr) {
            LoggerService.main.debug("Downloading latest version of file...")

            weak var file = file
            let tempFileLoc = try await self.downloadFile(from: url)

            let content = try Data(contentsOf: tempFileLoc)

            defer {
                // Remove the temporary file
                do {
                    try self.deleteFile(at: tempFileLoc)
                } catch {
                    LoggerService.main.error("Failed to delete temp file: \(error)")
                }
            }

            do {
                guard let file else {
                    throw FileError.fileWasNil
                }
                let url = try self.saveCourseFile(courseId: courseID, file: file, content: content)
                LoggerService.main.debug("File successfully saved at \(url.path())")

                return (content, url)
            } catch {
                LoggerService.main.error("Failed to save file. \(error)")
                throw error
            }
        } else {
            throw URLError(.badURL)
        }
    }

    // MARK: Global

    /// Get the string contents of a file. Supported types: doc, docx, txt.
    static func getContentsOfFile(at localURL: URL?) -> String {
        guard let localURL else { return "" }

        let fileExtension = localURL.pathExtension

        guard File.supportedPickableTypes.contains(fileExtension) else {
            return ""
        }

        if fileExtension == "pdf" {
            let pdf = PDFDocument(url: localURL)
            return pdf?.string ?? ""
        }

        let documentType = switch fileExtension {
        #if os(macOS)
        case "docx":
            NSAttributedString.DocumentType.officeOpenXML
        case "doc":
            NSAttributedString.DocumentType.docFormat
        #endif
        case "html":
            NSAttributedString.DocumentType.html
        default:
            NSAttributedString.DocumentType.plain
        }

        var text = ""

        if let data = try? Data(contentsOf: localURL) {
            if let attrString = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: documentType,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            ) {
                text = attrString.string
            }
        }

        return text
    }

    static func clearAllFiles() throws {
        guard let fileURL = coursesURL else {
            throw FileError.directoryInaccessible
        }

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: nil)

            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
                LoggerService.main.debug("Deleted: \(fileURL.lastPathComponent)")
            }

            LoggerService.main.debug("All files in \(fileURL.path) have been deleted.")
        } catch {
            LoggerService.main.error("Error deleting files: \(error.localizedDescription)")
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
            LoggerService.main.error("Error downloading file: \(response)")
            throw URLError(.badServerResponse)
        }

        return tempUrl
    }

    private func destinationPath(courseId: String, fileId: String, type: FileType) throws -> URL {
        guard let coursesURL = Self.coursesURL else {
            throw FileError.directoryInaccessible
        }

        var pathURL = coursesURL
            .appendingPathComponent(courseId)
            .appendingPathComponent("files")

        pathURL.appendPathComponent(fileId + (type.formatExtension))

        return pathURL
    }

    private func deleteFile(at url: URL) throws {
        guard Self.fileManager.fileExists(atPath: url.path(percentEncoded: false)) else {
            throw FileError.directoryInaccessible
        }

        do {
            try Self.fileManager.removeItem(at: url)
            LoggerService.main.debug("Deleted file at \(url.path())")
        } catch {
            LoggerService.main.error("Failed to delete file: \(error.localizedDescription)")
            throw error
        }
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
