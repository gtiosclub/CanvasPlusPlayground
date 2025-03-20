//
//  SubmitAssignmentRequest.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 3/7/25.
//

import Foundation

struct SubmitAssignmentRequest: NoReturnAPIRequest {
    let courseID: String
    let assignmentID: String

    var path: String {
        "courses/\(courseID)/assignments/\(assignmentID)/submissions"
    }

    let textComment: String?
    let submissionType: SubmissionType
    let submission_body: String?
    let url: String?
    let fileIDs: [Int]?
    var queryParameters: [QueryParameter] = []
    var method:RequestMethod { .POST }
    
    var body: Data? {
        let dict: [String: Any] = [
            "submission": [
                "submission_type": submissionType.rawValue,
                "text_comment": textComment,
                "body": submission_body,
                "file_ids": fileIDs,
                "url": url,
            ]
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
            print(jsonData)
            return jsonData
        }
        
        return nil
    }
}
