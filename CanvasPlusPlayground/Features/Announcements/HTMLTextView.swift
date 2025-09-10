//
//  AsyncAttributedText.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/15/24.
//

import SwiftUI
import WebKit
#if os(macOS)
import AppKit
#endif

struct HTMLTextView: View {
    let htmlText: String

    @State private var contentHeight: CGFloat = 250
    @Environment(\.sizeCategory) private var sizeCategory

    private var fontScale: CGFloat {
        switch sizeCategory {
        case .extraSmall: return 0.75
        case .small: return 0.85
        case .medium: return 0.95
        case .large: return 1.0
        case .extraLarge: return 1.12
        case .extraExtraLarge: return 1.20
        case .extraExtraExtraLarge: return 1.28
        case .accessibilityMedium: return 1.36
        case .accessibilityLarge: return 1.44
        case .accessibilityExtraLarge: return 1.52
        case .accessibilityExtraExtraLarge: return 1.60
        case .accessibilityExtraExtraExtraLarge: return 1.68
        @unknown default: return 1.0
        }
    }

    init(htmlText: String) {
        self.htmlText = htmlText
    }

    var body: some View {
        HTMLWebView(htmlText: htmlText, contentHeight: $contentHeight, fontScale: fontScale)
    }
}

#if os(macOS)
private struct HTMLWebView: NSViewRepresentable {
    let htmlText: String
    @Binding var contentHeight: CGFloat
    let fontScale: CGFloat

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let styledHTML = """
        <head>
          <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'>
        </head>

        <style>
          img {
            max-width: 100%;
            height: auto;
            display: block;   /* optional: removes inline gaps */
          }
          @media (prefers-color-scheme: dark) {
            body {
              color: #fff;
              background: transparent !important;
            }
          }
          @media (prefers-color-scheme: light) {
            body {
              color: #000;
              background: transparent !important;
            }
          }
        </style>
        """ + htmlText
        webView.loadHTMLString(styledHTML, baseURL: nil)
    }
}
#else
private struct HTMLWebView: UIViewRepresentable {
    let htmlText: String
    @Binding var contentHeight: CGFloat
    let fontScale: CGFloat

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let styledHTML = """
        <head>
          <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'>
        </head>

        <style>
          img {
            max-width: 100%;
            height: auto;
            display: block;   /* optional: removes inline gaps */
          }
          @media (prefers-color-scheme: dark) {
            body {
              color: #fff;
              background: transparent !important;
            }
          }
          @media (prefers-color-scheme: light) {
            body {
              color: #000;
              background: transparent !important;
            }
          }
        </style>
        """ + htmlText
        webView.loadHTMLString(styledHTML, baseURL: nil)
    }
}
#endif
