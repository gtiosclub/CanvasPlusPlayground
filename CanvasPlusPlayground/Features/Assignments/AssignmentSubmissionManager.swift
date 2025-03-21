//
//  AssignmentSubmissionManager.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 3/11/25.
//

import Foundation
@Observable
public class AssignmentSubmissionManager {
    let assignment: Assignment

    init(assignment: Assignment) {
        self.assignment = assignment
    }

    func submitAssignment(withText text: String) async throws {
        // make and send submission request
        guard let courseID = assignment.courseId?.asString else {
            throw AssignmentSubmissionError.missingCourseID
        }
        let request = CanvasRequest.submitAssignment(
            courseID: courseID,
            assignmentID: assignment.id,
            submissionType: .onlineTextEntry,
            submissionBody: text
        )
        try await CanvasService.shared.fetch(request)
    }

    func submitFileAssignment(forFiles urls: [URL]) async throws {
        guard let courseID = assignment.courseId?.asString else {
            throw AssignmentSubmissionError.missingCourseID
        }

        let fileIDs = await withTaskGroup(of: Int.self, returning: [Int].self) { taskGroup in
            for url in urls {
                taskGroup.addTask {
                    do {
                        return try await self.uploadFile(fileURL: url)
                    } catch {
                        LoggerService.main.error("Error uploading file: \(url)\n \(error)")
                        return -1
                    }
                }
            }

            var fileids = [Int]()
            for await result in taskGroup {
                fileids.append(result)
            }
            return fileids
        }

        let submissionRequest = CanvasRequest.submitAssignment(
            courseID: courseID,
            assignmentID: assignment.id,
            submissionType: .onlineUpload,
            fileIDs: fileIDs.filter { $0 != -1 }
        )
        do {
            try await CanvasService.shared.fetch(submissionRequest)
        } catch {
            LoggerService.main.error("Error creating submission file for assignment: \(self.assignment.name)\n \(error)")
        }
    }

    // Returns fileID
    func uploadFile(fileURL url: URL) async throws -> Int {
        let filename = url.lastPathComponent
        let fileData = try Data(contentsOf: url)
        let size = fileData.count

        guard let courseID = assignment.courseId?.asString else {
            // TODO: Error handle
            return -1
        }

        let notificationRequest = CanvasRequest.notifyFileUpload(
            courseID: courseID,
            assignmentID: assignment.id,
            filename: filename,
            fileSizeInBytes: size
        )

        guard let notificationResponse = try await CanvasService.shared.fetch(notificationRequest).first else {
            throw AssignmentSubmissionError.notificationResponseFailure
        }

        let mime: MimeType = url.pathExtension.lowercased() == "txt" ? .txt : .other

        let uploadRequest = CanvasRequest.performFileUpload(
            path: notificationResponse.uploadURL,
            keyValues: notificationResponse.uploadParams,
            filename: filename,
            fileData: fileData,
            mimeType: mime
        )

        let (_, uploadResponse) = try await CanvasService.shared.fetchResponse(uploadRequest)

        let httpResponse = uploadResponse as! HTTPURLResponse
        guard let locationString = httpResponse.value(forHTTPHeaderField: "Location") else {
            throw AssignmentSubmissionError.uploadResponseLocationMissing
        }

        let confirmationRequest = CanvasRequest.confirmFileUpload(path: locationString)
        let (finalData, _) = try await CanvasService.shared.fetchResponse(confirmationRequest)
        let finalResponseStruct = try JSONDecoder().decode(UploadFileConfirmationResponse.self, from: finalData)
        return finalResponseStruct.id
    }
}

enum SubmissionError: Error {
    case unsupported, invalidType
}

struct FileWrapper: Codable {
    let key: String
    let data: Data
}

enum MimeType: String {
    case txt = "text/plain", other = "application/octet-stream"
}

enum AssignmentSubmissionError: Error {
    case missingCourseID, notificationResponseFailure, uploadResponseLocationMissing
}
