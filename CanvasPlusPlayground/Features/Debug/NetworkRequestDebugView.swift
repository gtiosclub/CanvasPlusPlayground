//
//  CanvasPlusPlaygroundApp.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 8/29/25.
//

#if DEBUG
import SwiftUI

struct NetworkRequestDebugView: View {
    @Environment(NetworkRequestRecorder.self) private var recorder

    // Maintain the current selection
    @State private var selectedRecordID: NetworkRequestRecorder.NetworkRequestResponsePair.ID?
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
        let pair: NetworkRequestRecorder.NetworkRequestResponsePair
        
        @State private var wordWrapEnabled = true
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if wordWrapEnabled {
                        Text(pair.formattedDetailText)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    } else {
                        ScrollView(.horizontal) {
                            Text(pair.formattedDetailText)
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
                    Toggle("Toggle word wrap", systemImage: .textJustifyLeft, isOn: $wordWrapEnabled)
                }
            }
        }
    }
}

#endif
