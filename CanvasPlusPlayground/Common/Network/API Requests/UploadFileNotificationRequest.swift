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
    var path: String { "courses/\(courseID)/assignments/\(assignmentID)/submissions/self/files" }
    var queryParameters: [QueryParameter] = []
    typealias Subject = UploadFileNotificationResponse
    let courseID: String
    let assignmentID: String
    var method:RequestMethod { .POST }

    // Parameters
    let name: String // name of file
    let size: Int // Size in bytes
    let contentType: String? // if not provided, guesses based on file extension
    let onDuplicate: DuplicateCondition?
    var body: Data? {
        let dict:[String: Any] = [
            "name": name,
            "size": size,
            "content_type": contentType as Any,
            "on_duplicate": onDuplicate?.rawValue as Any
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
            return jsonData
        }
        return nil
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
