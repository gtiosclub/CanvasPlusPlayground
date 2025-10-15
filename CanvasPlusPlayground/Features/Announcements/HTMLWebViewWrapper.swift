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

struct HTMLWebViewWrapper: View {
    let htmlText: String
    let courseID: String // for deep link navigation purposes
    @State private var contentHeight: CGFloat = 250
    @State private var didFinishLoading:Bool = false

    init(htmlText: String, courseID: String) {
        self.htmlText = htmlText
        self.courseID = courseID
    }

    var body: some View {
        ZStack {
            HTMLWebView(htmlText: htmlText, courseID: courseID, didFinishLoading: $didFinishLoading)
            if !didFinishLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.thinMaterial)
            }
        }
        .frame(height: 300)
    }
}

private struct HTMLWebView: PlatformRepresentable {
    let htmlText: String
    let courseID: String
    @Binding var didFinishLoading: Bool
    @Environment(NavigationModel.self) var navigationModel
    
    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate {
        let onDestinationLink: (CanvasURLService.URLServiceResult) async -> Void
        var didFinishLoading: Binding<Bool>
        
        init(didFinishLoading: Binding<Bool>, onDestinationLink: @escaping (CanvasURLService.URLServiceResult) async -> Void) {
            self.didFinishLoading = didFinishLoading
            self.onDestinationLink = onDestinationLink
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async { self.didFinishLoading.wrappedValue = true }
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

    func makeCoordinator() -> Coordinator {
        Coordinator(didFinishLoading: $didFinishLoading) {
            await navigationModel.handleURLSelection(result: $0, courseID: courseID)
        }
    }

    // Shared HTML builder
    private func styledHTML() -> String {
#if os(macOS)
        return """
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
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
                    }
                }
                @media (prefers-color-scheme: light) {
                    body {
                        color: #000;
                        background: transparent !important;
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
                    }
                }
            </style>
        """ + self.htmlText
#else
        return """
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
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
                }
            }
            @media (prefers-color-scheme: light) {
                body {
                    color: #000;
                    background: transparent !important;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
                }
            }
    </style>
    """ + htmlText

#endif
    }

    // MARK: - Platform views
#if os(macOS)
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        DispatchQueue.global(qos: .userInitiated).async {
            let html = styledHTML()
            DispatchQueue.main.async { webView.loadHTMLString(html, baseURL: nil) }
        }
    }
#else
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        DispatchQueue.global(qos: .userInitiated).async {
            let html = styledHTML()
            DispatchQueue.main.async { webView.loadHTMLString(html, baseURL: nil) }
        }
    }
#endif
}
