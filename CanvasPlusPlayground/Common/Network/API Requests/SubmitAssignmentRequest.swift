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

    var method: RequestMethod { .POST }

    var contentType: String? { "application/json" }

    var body: Data? {
        let submission = Submission(
            submisssionType: submissionType,
            textComment: textComment,
            submissionBody: submissionBody,
            fileIDs: fileIDs,
            url: url
        )

        let wrapper = ["submission": submission]
        return try? JSONEncoder().encode(wrapper)
    }
}

extension SubmitAssignmentRequest {
    struct Submission: Codable {
        let submisssionType: SubmissionType
        let textComment: String?
        let submissionBody: String?
        let fileIDs: [Int]?
        let url: String?

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case submisssionType = "submission_type"
            case textComment = "text_comment"
            case submissionBody = "body"
            case fileIDs = "file_ids"
            case url
        }
    }
}
