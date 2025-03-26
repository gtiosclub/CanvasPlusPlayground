//
//  UploadFileTransmissionRequest.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 3/23/25.
//

import Foundation

struct UploadFileTransmissionRequest: APIRequest {
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
                body.append(Data("--\(boundary)\r\n".utf8))
                body.append(Data("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".utf8))
                body.append(Data("\(value)\r\n".utf8))
            }
        }

        // Append file data
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".utf8))
        body.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
        body.append(fileData)
        body.append(Data("\r\n".utf8))

        // End boundary
        body.append(Data("--\(boundary)--\r\n".utf8))
        return body
    }
}
