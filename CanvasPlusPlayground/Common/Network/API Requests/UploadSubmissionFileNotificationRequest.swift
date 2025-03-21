//
//  UploadSubmissionFileRequest.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 3/11/25.
//

import Foundation
// 3 step process

// First tell canvas about the file upload and get a token back

struct UploadSubmissionFileNotificationRequest: APIRequest {
    var path: String { "courses/\(courseID)/assignments/\(assignmentID)/submissions/self/files" }
    var queryParameters: [QueryParameter] = []
    typealias Subject = UploadSubmissionFileNotificationResponse
    let courseID: String
    let assignmentID: String
    var method:RequestMethod { .POST }

    // Parameters
    let name: String // name of file
    let size: Int // Size in bytes
    let contentType: String? // if not provided, guesses based on file extension
    let on_duplicate: DuplicateCondition?
    var body: Data? {
        let dict:[String: Any] = [
            "name": name,
            "size": size,
            "content_type": contentType as Any,
            "on_duplicate": on_duplicate?.rawValue as Any
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

struct UploadSubmissionFileNotificationResponse: APIResponse {
    let uploadURL: String
    let uploadParams: [String: String?]

    enum CodingKeys: String, CodingKey {
        case uploadURL = "upload_url"
        case uploadParams = "upload_params"
    }
}

// Upload notification request
// File upload request
// upload confirmation request
// Next, canvas sends you an endpoint to upload the file to

struct UploadSubmissionFileUploadRequest: APIRequest {
    typealias Subject = UploadSubmissionFileConfirmationResponse
    
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


struct UploadSubmissionFileConfirmationResponse: APIResponse {
    let id: Int
    let url: String
    let contentType: String
    let displayName: String
    let size: Int

    enum CodingKeys: String, CodingKey {
        case id, url, contentType = "content-type", displayName = "display_name", size
    }
}

struct UploadSubmissionFileConfirmationRequest: APIRequest {
    typealias Subject = UploadSubmissionFileConfirmationResponse
    
    var path: String
    var queryParameters: [QueryParameter] = []
    var method: RequestMethod { .GET }
    var forceURL: String? { path }
    var contentLength: String? { "0" }
}
