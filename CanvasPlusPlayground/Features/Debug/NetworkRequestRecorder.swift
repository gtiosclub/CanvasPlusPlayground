//
//  NetworkRequestRecorder.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 8/29/25.
//
#if DEBUG
import Foundation

@Observable
final class NetworkRequestRecorder {
    static let shared = NetworkRequestRecorder()
    private init() {}
    var counter = 0
    var records: [NetworkRequestResponsePair] = []
    
    static let networkRequestDebugID = "network-request-recorder"
    
    func addRecord(request: URLRequest, response: URLResponse?, responseBody: Data) {
        let pair = NetworkRequestResponsePair(request: request, response: response, responseBody: responseBody, timestamp: Date.now, id: counter)
        records.append(pair)
        counter += 1
    }
    
    struct NetworkRequestResponsePair: Identifiable, Hashable {
        let request: URLRequest
        let response: URLResponse? // who ever said we were going to get a response...
        let responseBody: Data?
        let timestamp: Date
        let id: Int
        
        var formattedDetailText: String {
            var lines: [String] = []
            
            // Request
            lines.append("Request")
            lines.append("  Method: \(self.request.httpMethod ?? "<none>")")
            lines.append("  URL: \(self.request.url?.absoluteString ?? "<none>")")
            
            if let headers = self.request.allHTTPHeaderFields, !headers.isEmpty {
                lines.append("  Headers:")
                for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
                    lines.append("    \(key): \(value)")
                }
            } else {
                lines.append("  Headers: <none>")
            }
            
            if let body = self.request.httpBody {
                let bodyString = body.jsonToPrettyString() ?? "<binary data>"
                lines.append("  Body:")
                lines.append(bodyString.split(separator: "\n").map { "    \($0)" }.joined(separator: "\n"))
            } else {
                lines.append("  Body: <none>")
            }
            
            lines.append("")
            
            // Response
            lines.append("Response")
            if let response = self.response {
                lines.append("  URL: \(response.url?.absoluteString ?? "<none>")")
                lines.append("  MIME Type: \(response.mimeType ?? "<none>")")
                lines.append("  Expected Content Length: \(response.expectedContentLength)")
                if let httpResponse = response as? HTTPURLResponse {
                    lines.append("  Status Code: \(httpResponse.statusCode)")
                    if !httpResponse.allHeaderFields.isEmpty {
                        lines.append("  Headers:")
                        for (key, value) in httpResponse.allHeaderFields.sorted(by: { "\($0.key)" < "\($1.key)" }) {
                            lines.append("    \(key): \(value)")
                        }
                    }
                }
                
                if let responseBody = self.responseBody {
                    let bodyString = responseBody.jsonToPrettyString() ?? "<binary data>"
                    lines.append("  Body:")
                    lines.append(bodyString.split(separator: "\n").map { "    \($0)" }.joined(separator: "\n"))
                } else {
                    lines.append("  Body: <none>")
                }
            } else {
                lines.append("  No response")
            }
            
            return lines.joined(separator: "\n")
        }
    }
}

#endif

extension Data {
    fileprivate func jsonToPrettyString() -> String? {
        if let json = try? JSONSerialization.jsonObject(with: self, options: .mutableContainers),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            return String(decoding: jsonData, as: UTF8.self)
        } else {
            return nil
        }
    }
}
