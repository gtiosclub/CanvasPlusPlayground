//
//  CanvasPlusPlaygroundApp.swift
//  CanvasPlusPlayground
//
//  Created by Ethan FOx on 8/29/25.
//

import SwiftUI


let networkRequestDebugID = "network-request-recorder"

struct NetworkRequestDebugView: View {
    @Environment(NetworkRequestRecorder.self) private var recorder

    // Maintain the current selection
    @State private var selectedRecordID: NetworkRequestResponsePair.ID?

    var body: some View {
        NavigationSplitView {
            // Sidebar: List of records
            List(recorder.records, selection: $selectedRecordID) { record in
                HStack {
                    Text(record.request.httpMethod ?? "???")
                    Text(record.request.url?.relativePath ?? "No path")
                }
                .id(record.id)
            }
            .navigationTitle("Network Records")
            .navigationSplitViewColumnWidth(350)
        } detail: {
            // Detail: Show details for selected
            let selectedRecord = recorder.records.first(where: { $0.id == selectedRecordID })
            if let pair = selectedRecord {
                NetworkRecordDetailView(pair: pair)
            } else {
                Text("Select a request")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    struct NetworkRecordDetailView: View {
        let pair: NetworkRequestResponsePair
        
        @State private var wordWrapEnabled = true
        
        private var formattedDetailText: String {
            var lines: [String] = []
            
            // Request
            lines.append("Request")
            lines.append("  Method: \(pair.request.httpMethod ?? "<none>")")
            lines.append("  URL: \(pair.request.url?.absoluteString ?? "<none>")")
            
            if let headers = pair.request.allHTTPHeaderFields, !headers.isEmpty {
                lines.append("  Headers:")
                for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
                    lines.append("    \(key): \(value)")
                }
            } else {
                lines.append("  Headers: <none>")
            }
            
            if let body = pair.request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
                lines.append("  Body:")
                lines.append(bodyString.split(separator: "\n").map { "    \($0)" }.joined(separator: "\n"))
            } else {
                lines.append("  Body: <none>")
            }
            
            lines.append("")
            
            // Response
            lines.append("Response")
            if let response = pair.response {
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
            } else {
                lines.append("  No response")
            }
            
            return lines.joined(separator: "\n")
        }
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if wordWrapEnabled {
                        Text(formattedDetailText)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    } else {
                        ScrollView(.horizontal) {
                            Text(formattedDetailText)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(nil)
                                .textSelection(.enabled)
                                .padding(.bottom, 8)
                        }
                    }
                }
                .padding()
                .textSelection(.enabled)
            }
            .toolbar {
                ToolbarItem {
                    Toggle("Toggle word wrap", systemImage: "text.justify.left", isOn: $wordWrapEnabled)
                }
            }
        }
    }
}

