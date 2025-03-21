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
    typealias Subject = UploadFileNotificationResponse
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
// Upload notification request
// File upload request
// upload confirmation request
// Next, canvas sends you an endpoint to upload the file to


struct UploadFileNotificationResponse: APIResponse {
    let uploadURL: String
    let uploadParams: [String: String?]

    enum CodingKeys: String, CodingKey {
        case uploadURL = "upload_url"
        case uploadParams = "upload_params"
    }
}

struct UploadFileConfirmationResponse: Codable {
    let id: Int
    let url: String
    let contentType: String
    let displayName: String
    let size: Int

    enum CodingKeys: String, CodingKey {
        case id, url, contentType = "content-type", displayName = "display_name", size
    }
}
