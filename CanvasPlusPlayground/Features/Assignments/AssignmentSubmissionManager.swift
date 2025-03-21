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

    func submitAssignment(withText text: String) async {
        // make and send submission request
        guard let courseID = assignment.courseId?.asString else {
            // TODO: Error handle
            return
        }
        let request = CanvasRequest.submitAssignment(courseID: courseID, assignmentID: assignment.id, submissionType: .onlineTextEntry, submissionBody: text)
        do {
            try await CanvasService.shared.fetch(request)
        } catch {
            print(error)
        }
    }

    func submitFileAssignment(forFiles urls: [URL]) async {
        print("Entering submit file assignment")
        // for each file
            // tell canavas about the file upload and get a token
            // upload file data with the provided URL
            // confirm upload success
        var fileIDs:[Int] = []

        guard let courseID = assignment.courseId?.asString else {
            // TODO: Error handle
            return
        }

        for url in urls {
            let filename = url.lastPathComponent
            do {
                let fileData = try Data(contentsOf: url)
                let size = fileData.count
                guard let courseID = assignment.courseId?.asString else {
                    // TODO: Error handle
                    return
                }
                let notificationRequest = CanvasRequest.notifyFileUpload(courseID: courseID, assignmentID: assignment.id, filename: filename, fileSizeInBytes: size)
                guard let notificationResponse = try await CanvasService.shared.fetch(notificationRequest).first else {
                    // TODO: BRUH
                    return
                }
                
                let mime: MimeType = url.pathExtension.lowercased() == "txt" ? .txt : .other
                
                let uploadRequest = CanvasRequest.uploadSubmissionFile(path: notificationResponse.uploadURL, keyValues: notificationResponse.uploadParams, filename: filename, fileData: fileData, mimeType: mime)
                
                let (_, uploadResponse) = try await CanvasService.shared.fetchResponse(uploadRequest)
                
                let httpResponse = uploadResponse as! HTTPURLResponse

                if httpResponse.value(forHTTPHeaderField: "Location") == nil {
                    // TODO: Handle Error
                    return
                }
                
                guard let locationString = httpResponse.value(forHTTPHeaderField: "Location") else {
                    //TODO: Error
                    return
                }
                let confirmationRequest = CanvasRequest.confirmFileUpload(path: locationString)
                let (finalData, _) = try await CanvasService.shared.fetchResponse(confirmationRequest)
                let finalResponseStruct = try JSONDecoder().decode(UploadSubmissionFileConfirmationResponse.self, from: finalData)
                fileIDs.append(finalResponseStruct.id)
            } catch {
                print(error)
            }

            let submissionRequest = CanvasRequest.submitAssignment(courseID: courseID, assignmentID: assignment.id, submissionType: .onlineUpload, fileIDs: fileIDs)
            do {
                try await CanvasService.shared.fetch(submissionRequest)
            } catch {
                print(error)
            }
        }
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
