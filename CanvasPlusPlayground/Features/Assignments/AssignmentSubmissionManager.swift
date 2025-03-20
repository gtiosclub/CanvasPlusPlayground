//
//  AssignmentSubmissionManager.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 3/11/25.
//

import Foundation
@Observable
public class AssignmentSubmissionManager {
    let assignment: Assignment

    init(assignment: Assignment) {
        self.assignment = assignment
    }

    func submitAssignment(withText text: String) async {
        // make and send submission request
        guard let courseID = assignment.courseId?.asString else {
            //TODO: Error handle
            return
        }
        let request = CanvasRequest.submitAssignment(courseID: courseID, assignmentID: assignment.id, submissionType: .onlineTextEntry, submissionBody: text)
        do {
            try await CanvasService.shared.fetch(request)
        } catch {
            print(error)
        }
    }

    func submitFileAssignment(forFiles urls: [URL]) async {
        print("Entering submit file assignment")
        // for each file
            // tell canavas about the file upload and get a token
            // upload file data with the provided URL
            // confirm upload success
        var fileIDs:[Int] = []
        
        guard let courseID = assignment.courseId?.asString else {
            //TODO: Error handle
            return
        }
        
        for url in urls {
            let filename = url.lastPathComponent
            do {
                let file_data = try Data(contentsOf: url)
                let size = file_data.count
                guard let courseID = assignment.courseId?.asString else {
                    //TODO: Error handle
                    return
                }
                let request = CanvasRequest.uploadFileSubmission(courseID: courseID, assignmentID: assignment.id, filename: filename, fileSizeInBytes: size)
                
                guard let response = try await CanvasService.shared.fetch(request).first else {
                    //TODO: BRUH
                    return
                }
                
                print("URL:\(response.uploadURL)")
                print("Params: \(response.uploadParams)")
                let uploadURL = response.uploadURL
                var uploadRequest = URLRequest(url: URL(string: uploadURL)!)
                uploadRequest.httpMethod = "POST"
                let boundary = UUID().uuidString
                uploadRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                var body = Data()
                
                // Append upload params
                for (key, value) in response.uploadParams {
                    if let value = value { // Ignore nil values
                        body.append("--\(boundary)\r\n".data(using: .utf8)!)
                        body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                        body.append("\(value)\r\n".data(using: .utf8)!)
                    }
                }

                // Append file data
                let mimeType = "text/plain" // Change this based on file type
                
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
                body.append(file_data)
                body.append("\r\n".data(using: .utf8)!)
                

                // End boundary
                body.append("--\(boundary)--\r\n".data(using: .utf8)!)

                uploadRequest.httpBody = body
                
                let (data, uploadResponse) = try await URLSession.shared.data(for: uploadRequest)
                
                let httpResponse = uploadResponse as! HTTPURLResponse
                
                if (httpResponse.value(forHTTPHeaderField: "Location") == nil) {
                    //TODO: Handle Error
                    return
                }
                let locationString = httpResponse.value(forHTTPHeaderField: "Location") as! String
                let locationURL = URL(string: locationString)!
                var confirmationRequest = URLRequest(url: locationURL)
                confirmationRequest.httpMethod = "POST"
                confirmationRequest.setValue("0", forHTTPHeaderField: "Content-Length")
                confirmationRequest.setValue("Bearer \(StorageKeys.accessTokenValue)", forHTTPHeaderField: "Authorization")
                
                let (finalData, finalResponse) = try await URLSession.shared.data(for: confirmationRequest)
                let finalResponseStruct = try JSONDecoder().decode(UploadFileConfirmationResponse.self, from: finalData)
                fileIDs.append(finalResponseStruct.id)
                print("Struct \(finalResponseStruct)")
            } catch {
                print(error)
            }
            
            let submissionRequest = CanvasRequest.submitAssignment(courseID: courseID, assignmentID: assignment.id, submissionType: .onlineUpload, fileIDs: fileIDs)
            do {
                try await CanvasService.shared.fetch(submissionRequest)
            } catch {
                print(error)
            }
            
        }
        
    }
    
}

enum SubmissionError: Error {
    case unsupported, invalidType
}

struct FileWrapper: Codable {
    let key: String
    let data: Data
}
