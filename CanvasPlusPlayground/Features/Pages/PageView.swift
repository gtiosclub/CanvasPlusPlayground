//
//  PageView.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 2/25/25.
//

import SwiftUI
import RichText
struct PageView: View {
    let page: Page

    var body: some View {
        ZStack {
            if let htmlContent = page.body, !htmlContent.isEmpty {
                RichText(html: htmlContent)
                    .colorScheme(.auto)                    // Auto light/dark mode
                    .lineHeight(170)                       // Line height percentage
                    .imageRadius(12)                       // Rounded image corners
                    .transparentBackground()               // Transparent background
                    .placeholder {                         // Loading Placeholder
                        Text("Loading email...")
                    }
                    .onMediaClick { media in               // Handle media clicks
                        switch media {
                        case .image(let src):
                            print("Image clicked: \(src)")
                        case .video(let src):
                            print("Video clicked: \(src)")
                        }
                    }
                    .onError { error in                    // Handle errors
                        print("RichText error: \(error)")
                    }
                HTMLView(html: htmlContent, courseID: page.courseID)
                    //.pickedItem(page)
            } else {
                ContentUnavailableView("No pages available", systemImage: "exclamationmark.bubble.fill")
            }
        }
        .navigationTitle(page.title ?? "Untitled")
    }
}
