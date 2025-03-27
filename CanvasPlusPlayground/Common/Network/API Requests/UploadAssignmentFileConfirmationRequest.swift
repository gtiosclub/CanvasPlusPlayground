//
//  UploadFileConfirmationRequest.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 3/23/25.
//

import Foundation

struct UploadAssignmentFileConfirmationRequest: APIRequest {
    typealias Subject = UploadAssignmentFileConfirmationResponse

    var path: String
    var queryParameters: [QueryParameter] = []
    var method: RequestMethod { .GET }
    var forceURL: String? { path }
    var contentLength: String? { "0" }
}

struct UploadAssignmentFileConfirmationResponse: APIResponse {
    let id: Int
    let url: String
    let contentType: String
    let displayName: String
    let size: Int

    enum CodingKeys: String, CodingKey {
        case id, url, contentType = "content-type", displayName = "display_name", size
    }
}
