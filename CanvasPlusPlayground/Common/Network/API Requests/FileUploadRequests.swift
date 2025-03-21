//
//  FileUploadRequests.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 3/11/25.
//

import Foundation

/*
 Uploading a file to Canvas is a 3 step process and involves 3 separate request-response
    1. First notify canvas that you are going to upload a file, this provides file metadata like size, type, etc
    2. Next, the file data is sent in the body of the second response
    3. Finally, after you have uploaded a the file, you need to ping an endpoint to confirm the upload
    More info here: https://canvas.instructure.com/doc/api/file.file_uploads.html
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

// MARK: Second, upload file data

struct UploadFileUploadRequest: APIRequest {
    typealias Subject = UploadFileConfirmationResponse

    var path: String
    var queryParameters: [QueryParameter] = []
    var method: RequestMethod { .POST }
    var contentType: String? { "multipart/form-data; boundary=\(boundary)" }
    var forceURL: String? { path }

    let boundary = UUID().uuidString
    let keyValues: [String: String?]
    let filename: String
    let fileData: Data
    let mimeType: String
    var body: Data? {
        var body = Data()

        // Append upload params
        for (key, value) in keyValues {
            if let value { // Ignore nil values
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }

        // Append file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)

        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}

// MARK: Third, confirm file upload

struct UploadFileConfirmationRequest: APIRequest {
    typealias Subject = UploadFileConfirmationResponse

    var path: String
    var queryParameters: [QueryParameter] = []
    var method: RequestMethod { .GET }
    var forceURL: String? { path }
    var contentLength: String? { "0" }
}

struct UploadFileConfirmationResponse: APIResponse {
    let id: Int
    let url: String
    let contentType: String
    let displayName: String
    let size: Int

    enum CodingKeys: String, CodingKey {
        case id, url, contentType = "content-type", displayName = "display_name", size
    }
}
