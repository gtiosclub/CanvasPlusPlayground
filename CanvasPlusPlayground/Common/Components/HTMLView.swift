//
//  HTMLView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 4/8/25.
//

import SwiftUI
@preconcurrency import WebKit
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct HTMLView: ViewRepresentable {
    @Environment(NavigationModel.self) private var navigationModel

    let html: String
    let courseID: Course.ID?

    #if os(iOS)
    func makeUIView(context: Context) -> WKWebView {
        makeView(context: context)
    }
    #else
    func makeNSView(context: Context) -> WKWebView {
        makeView(context: context)
    }
    #endif

    #if os(iOS)
    func updateUIView(_ uiView: WKWebView, context: Context) {
        updateView(uiView, context: context)
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        dismantleView(uiView)
    }
    #else
    func updateNSView(_ nsView: WKWebView, context: Context) {
        updateView(nsView, context: context)
    }

    static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        dismantleView(nsView)
    }
    #endif

    func makeCoordinator() -> Coordinator {
        Coordinator {
            await navigationModel.handleURLSelection(result: $0, courseID: courseID)
        }
    }

    func makeView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateView(_ view: WKWebView, context: Context) {
        let styledHTML = wrapHTMLWithCSS(html)
        view.loadHTMLString(styledHTML, baseURL: nil)
    }

    private func wrapHTMLWithCSS(_ htmlContent: String) -> String {
        let css = """
            <head>
                <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'>
            </head>
            <style>
                * {
                    box-sizing: border-box;
                }

                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', Arial, sans-serif;
                    font-size: 15px;
                    line-height: 1.5;
                    margin: 0;
                    padding: 16px;
                    background: transparent !important;
                    word-wrap: break-word;
                    -webkit-text-size-adjust: 100%;
                }

                /* Typography */
                h1, h2, h3, h4, h5, h6 {
                    font-weight: 600;
                    line-height: 1.3;
                    margin-top: 24px;
                    margin-bottom: 12px;
                }

                h1 { font-size: 28px; }
                h2 { font-size: 24px; }
                h3 { font-size: 20px; }
                h4 { font-size: 17px; }
                h5 { font-size: 15px; }
                h6 { font-size: 13px; }

                p {
                    margin: 0 0 12px 0;
                }

                /* Links */
                a {
                    text-decoration: none;
                    font-weight: 500;
                }

                a:hover {
                    text-decoration: underline;
                }

                /* Lists */
                ul, ol {
                    margin: 12px 0;
                    padding-left: 24px;
                }

                li {
                    margin: 6px 0;
                }

                /* Images */
                img {
                    max-width: 100%;
                    height: auto;
                    display: block;
                    border-radius: 8px;
                    margin: 12px 0;
                }

                /* Code */
                code {
                    font-family: 'SF Mono', Monaco, 'Courier New', monospace;
                    font-size: 13px;
                    padding: 2px 6px;
                    border-radius: 4px;
                }

                pre {
                    font-family: 'SF Mono', Monaco, 'Courier New', monospace;
                    font-size: 13px;
                    padding: 12px;
                    border-radius: 8px;
                    overflow-x: auto;
                    margin: 12px 0;
                }

                pre code {
                    padding: 0;
                    background: transparent !important;
                }

                /* Blockquotes */
                blockquote {
                    margin: 12px 0;
                    padding: 8px 16px;
                    border-left: 4px solid;
                }

                /* Tables */
                table {
                    border-collapse: collapse;
                    width: 100%;
                    margin: 12px 0;
                    border-radius: 8px;
                    overflow: hidden;
                }

                th, td {
                    padding: 10px 12px;
                    text-align: left;
                    border-bottom: 1px solid;
                }

                th {
                    font-weight: 600;
                }

                tr:last-child td {
                    border-bottom: none;
                }

                /* Horizontal rule */
                hr {
                    border: none;
                    height: 1px;
                    margin: 24px 0;
                }

                /* Dark mode */
                @media (prefers-color-scheme: dark) {
                    body {
                        color: rgba(255, 255, 255, 0.85);
                    }

                    a {
                        color: #64B5F6;
                    }

                    code {
                        background: rgba(255, 255, 255, 0.1);
                        color: rgba(255, 255, 255, 0.9);
                    }

                    pre {
                        background: rgba(255, 255, 255, 0.08);
                        color: rgba(255, 255, 255, 0.9);
                    }

                    blockquote {
                        border-left-color: rgba(255, 255, 255, 0.3);
                        background: rgba(255, 255, 255, 0.05);
                    }

                    th, td {
                        border-bottom-color: rgba(255, 255, 255, 0.15);
                    }

                    th {
                        background: rgba(255, 255, 255, 0.08);
                    }

                    hr {
                        background: rgba(255, 255, 255, 0.15);
                    }
                }

                /* Light mode */
                @media (prefers-color-scheme: light) {
                    body {
                        color: rgba(0, 0, 0, 0.85);
                    }

                    a {
                        color: #007AFF;
                    }

                    code {
                        background: rgba(0, 0, 0, 0.06);
                        color: rgba(0, 0, 0, 0.9);
                    }

                    pre {
                        background: rgba(0, 0, 0, 0.04);
                        color: rgba(0, 0, 0, 0.9);
                    }

                    blockquote {
                        border-left-color: rgba(0, 0, 0, 0.2);
                        background: rgba(0, 0, 0, 0.03);
                    }

                    th, td {
                        border-bottom-color: rgba(0, 0, 0, 0.12);
                    }

                    th {
                        background: rgba(0, 0, 0, 0.04);
                    }

                    hr {
                        background: rgba(0, 0, 0, 0.12);
                    }
                }
            </style>
        """

        return css + htmlContent
    }

    static func dismantleView(_ view: WKWebView) {
        view.stopLoading()
        view.navigationDelegate = nil

        view.loadHTMLString("", baseURL: nil)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let onDestinationLink: (CanvasURLService.URLServiceResult) async -> Void

        init(onDestinationLink: @escaping (CanvasURLService.URLServiceResult) async -> Void) {
            self.onDestinationLink = onDestinationLink
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            if navigationAction.navigationType == .linkActivated {
                if let url = navigationAction.request.url {
                    if let potentialDestination = CanvasURLService.determineNavigationDestination(
                        from: url
                    ) {
                        await onDestinationLink(potentialDestination)
                    } else {
                        #if os(iOS)
                        await UIApplication.shared.open(url)
                        #else
                        NSWorkspace.shared.open(url)
                        #endif
                    }

                    return .cancel
                }
            }

            return .allow
        }
    }
}

#if os(iOS)
typealias ViewRepresentable = UIViewRepresentable
#else
typealias ViewRepresentable = NSViewRepresentable
#endif
