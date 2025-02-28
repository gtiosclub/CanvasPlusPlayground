//
//  PageView.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 2/25/25.
//

import SwiftUI
import WebKit

struct PageView: View {
    let page: Page

    var body: some View {
        ZStack {
            if let htmlContent = page.body, !htmlContent.isEmpty {
                HTMLView(html: htmlContent)
            } else {
                ContentUnavailableView("No pages available", systemImage: "exclamationmark.bubble.fill")
            }
        }
        .navigationTitle(page.title ?? "Untitled")
    }
}

#if os(iOS)
import UIKit

struct HTMLView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(html, baseURL: nil)
    }
}

#elseif os(macOS)
import AppKit

struct HTMLView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(html, baseURL: nil)
    }
}
#endif
