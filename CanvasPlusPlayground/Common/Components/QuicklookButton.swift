//
//  QuicklookButton.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 11/10/25.
//

import Foundation
import SwiftUI
import QuickLook

struct QuickLookButton: View {

    let url: URL // file web url
    let fileName: String

    @State var showProgressView: Bool = false
    @State private var quickLookURL: URL? = nil

    var body: some View {
        VStack {
            Group {
                if showProgressView {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button("Quick Look", systemImage: "magnifyingglass", action: downloadFile)
                        .labelStyle(.iconOnly)
                }
            }
        }
        .quickLookPreview($quickLookURL)
    }

    func downloadFile() {
        showProgressView = true

        Task {
            guard let data = await url.downloadWebFile() else {
                LoggerService.main.error("Error downloading file")
                return
            }
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            do {
                try data.write(to: tempURL)
                quickLookURL = tempURL
            } catch {
                LoggerService.main.error("Failed to write file for Quick Look: \(error)")
            }

            showProgressView = false
        }
    }

}
