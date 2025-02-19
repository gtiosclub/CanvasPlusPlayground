//
//  DownloadService.swift
//  CanvasPlusPlayground
//
//  Created by João Pozzobon on 2/17/25.
//

import Foundation
#if os(macOS)
import AppKit
#endif
import SwiftData

class DownloadService: NSObject, URLSessionDownloadDelegate {
    private var session: URLSession!
    private var modelContext: ModelContext

    private static let fileManager: FileManager = .default

    static var shared = DownloadService()

    override init() {
        self.modelContext = ModelContext.shared
        super.init()
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

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

    @MainActor
    func createDownload(for file: File, course: Course, folderIds: [String]) async throws {
        let fileURL = try self.pathWithFolders(foldersPath: folderIds,
                                               courseId: course.id,
                                               fileId: file.id,
                                               type: .init(file: file))
        let download = Download(file: file, finalURL: fileURL)

        modelContext.insert(download)
        try? modelContext.save()

        let toast = Toast(type: .download(download))
        NavigationModel.shared.queueToast(toast)

        try await startDownload(download, course: course)
    }

    func startDownload(_ download: Download, course: Course) async throws {
        guard let url = URL(string: download.file.url ?? "") else {
            return
        }

        download.downloadTask = session.downloadTask(with: url)
        download.downloadTask?.delegate = self
        download.downloadTask?.taskDescription = download.id.uuidString
        download.downloadTask?.resume()

        print("Start download for \(download.file.filename)")

        try? modelContext.save()
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

    // MARK: URLSessionDownloadDelegate

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let idString = downloadTask.taskDescription, let id = UUID(uuidString: idString) else { return }

        if let item = self.fetchDownloadItem(by: id) {
            Task { @MainActor in
                item.progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                print(item.progress)
                try? modelContext.save()
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let idString = downloadTask.taskDescription, let id = UUID(uuidString: idString) else { return }

        if let item = self.fetchDownloadItem(by: id) {
            do {
                let parentDirURL = item.finalURL.deletingLastPathComponent()

                try Self.fileManager.createDirectory(
                    at: parentDirURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )

                try Self.fileManager.moveItem(at: location, to: item.finalURL)
                item.localURL = item.finalURL

                try? modelContext.save()

                let toast = Toast(type: .downloadFinished(item))
                NavigationModel.shared.queueToast(toast)

                print("File successfully saved at \(item.finalURL.path)")
            } catch {
                print("Failed to save file. \(error)")
            }
        }
    }

    private func fetchDownloadItem(by id: UUID) -> Download? {
        let fetchDescriptor = FetchDescriptor<Download>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(fetchDescriptor).first
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
