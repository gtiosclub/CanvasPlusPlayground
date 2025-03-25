//
//  SubmitAssignmentRequest.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 3/7/25.
//

import Foundation

struct SubmitAssignmentRequest: APIRequest {
    typealias Subject = SubmissionAPI
    let courseID: String
    let assignmentID: String

    var path: String {
        "courses/\(courseID)/assignments/\(assignmentID)/submissions"
    }

    let textComment: String?
    let submissionType: SubmissionType
    let submissionBody: String?
    let url: String?
    let fileIDs: [Int]?
    var queryParameters: [QueryParameter] = []
    var method:RequestMethod { .POST }
    var contentType: String? { "application/json" }
    var body: Data? {
        let dict: [String: [String: Any]] = [
            "submission": [
                "submission_type": submissionType.rawValue as Any,
                "text_comment": textComment as Any,
                "body": submissionBody as Any,
                "file_ids": fileIDs as Any,
                "url": url as Any
            ]
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
            return jsonData
        }

        return nil
    }
}
