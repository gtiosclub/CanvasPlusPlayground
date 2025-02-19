//
//  FileViewer.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/9/24.
//

import SwiftUI

struct FileViewer: View {
    @Environment(\.dismiss) private var dismiss

    let download: Download

    @State private var url: URL?

    var body: some View {
        Group {
            if let url = download.localURL {
                QuickLookPreview(url: url) { dismiss() }
                    #if os(iOS)
                    .navigationBarBackButtonHidden()
                    .ignoresSafeArea()
                    #else
                    .toolbar {
                        ShareLink(item: url)
                    }
                    #endif
            } else {
                ContentUnavailableView("Unable to preview file.", systemImage: "xmark.rectangle.fill")
                #if os(iOS)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
                #endif
            }
        }
    }
}
