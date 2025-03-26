//
//  FileUploadRequests.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 3/11/25.
//

import Foundation

/*
 Uploading a file to Canvas is a 3 step process and involves 3 separate request-response
    1. First notify canvas that you are going to upload a file, this provides file metadata like size, type, etc (notification)
    2. Next, the file data is sent in the body of the second response (transmission)
    3. Finally, after you have uploaded a the file, you need to ping an endpoint to confirm the upload (confirmation)
    More info here: https://canvas.instructure.com/doc/api/file.file_uploads.html
    For information about the other request please reference UploadFileTransmissionRequest.swift and UploadFileConfirmationRequest.swift
 */

// MARK: First, notify Canvas of intentions to upload a file

struct UploadFileNotificationRequest: APIRequest {
    // User provided parameters
    let courseID: String
    let assignmentID: String
    let name: String // name of file
    let size: Int // Size in bytes

    typealias Subject = UploadFileNotificationResponse
    var method: RequestMethod { .POST }
    var path: String { "courses/\(courseID)/assignments/\(assignmentID)/submissions/self/files" }
    var queryParameters: [QueryParameter] = []
    let boundary = UUID().uuidString
    var contentType: String? { "multipart/form-data; boundary=\(boundary)" }

    var body: Data? {
        // Create the multipart body
        var body = Data()

        // Append name field
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"name\"\r\n\r\n".utf8))
        body.append(Data("testsubmission.pdf\r\n".utf8))
        // Append size field
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"size\"\r\n\r\n".utf8))
        body.append(Data("\(size)\r\n".utf8))
        // Close the body with boundary
        body.append(Data("--\(boundary)--\r\n".utf8))

        return body
    }

    enum DuplicateCondition: String {
        case overwrite, rename
    }
}

struct UploadFileNotificationResponse: APIResponse {
    let uploadURL: String
    let uploadParams: [String: String?]

    enum CodingKeys: String, CodingKey {
        case uploadURL = "upload_url"
        case uploadParams = "upload_params"
    }
}
