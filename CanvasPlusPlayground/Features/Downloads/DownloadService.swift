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

    @MainActor
    func startDownload(for file: File, course: Course) async throws {
        let download = Download(file: file)
        modelContext.insert(download)
        try? modelContext.save()

        let toast = Toast(type: .download, title: file.displayName, subtitle: "Downloading", duration: 5)
        NavigationModel.shared.queueToast(toast)

        try await startDownload(for: download, course: course)
    }

    func startDownload(for download: Download, course: Course) async throws {
        guard let url = URL(string: download.file.url ?? "") else {
            return
        }

//        download.downloadTask = URLSession.shared.downloadTask(with: url) { (url, _, error) in
//            if let error = error {
//                print("Error downloading file: \(error)")
//                return
//            }
//
//            guard let url = url else {
//                return
//            }
//
//            do {
//                let content = try Data(contentsOf: url)
//
//                let url = try self.saveCourseFile(courseId: course.id, folderIds: [], file: download.file, content: content)
//                print("File successfully saved at \(url.path())")
//
//                download.localURL = url
//            } catch {
//                print("Failed to save file. \(error)")
//            }
//        }

        download.downloadTask = session.downloadTask(with: url)
        download.downloadTask?.delegate = self
        download.downloadTask?.taskDescription = download.id.uuidString
        download.downloadTask?.resume()

        print("Start download for \(download.file.filename)")

        try? modelContext.save()
    }

    func courseFile(
        for file: File,
        course: Course,
        foldersPath: [String],
        localCopyReceived: (Data?, URL) -> Void
    ) async throws -> (Data, URL) {
        if let fileLoc = self.setLocationForCourseFile(file, course: course, foldersPath: foldersPath),
           let data = try? Data(contentsOf: fileLoc) {
            localCopyReceived(data, fileLoc)
        }

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

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let idString = downloadTask.taskDescription, let id = UUID(uuidString: idString) else { return }

        Task { @MainActor in
            if let item = self.fetchDownloadItem(by: id) {
                item.progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                print(item.progress)
                try? modelContext.save()
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Finished")
    }

    private func fetchDownloadItem(by id: UUID) -> Download? {
        let fetchDescriptor = FetchDescriptor<Download>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(fetchDescriptor).first
    }
}
