//
//  HTMLView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 9/30/25.
//  Merged on 9/30/25.
//

import SwiftUI

#if os(iOS)
import SwiftUIHTML
import Fuzi
import UIKit
#else
import WebKit
import AppKit
#endif

struct HTMLView: View {
    @Environment(NavigationModel.self) private var navigationModel
    
    let html: String
    let courseID: Course.ID?
    
    var body: some View {
        #if os(iOS)
        iosBody
        #else
        crossPlatformBody
        #endif
    }

    #if os(iOS)
    /// The body for iOS, using SwiftUIHTML for native rendering.
    private var iosBody: some View {
        SwiftUIHTML.HTMLView(html: html, parser: HTMLFuziParser())
    }
    #else
    /// The body for non-iOS platforms, using a WKWebView wrapper.
    private var crossPlatformBody: some View {
        WebViewRepresentable(html: html, courseID: courseID)
    }
    #endif
}

// MARK: - iOS-Specific Parser
#if os(iOS)
/// A custom parser for SwiftUIHTML using the Fuzi library.
struct HTMLFuziParser: HTMLParserable {
    func parse(html: String) -> HTMLNode {
        do {
            let document = try HTMLDocument(string: html, encoding: .utf8)
            
            if let body = document.body {
                return try elementToHTMLNode(element: body)
            } else if let root = document.root {
                return try elementToHTMLNode(element: root)
            } else {
                return createErrorNode("No root element found")
            }
        } catch {
            return createErrorNode("Parse error: \(error.localizedDescription)")
        }
    }
    
    private func elementToHTMLNode(element: Fuzi.XMLElement) throws -> HTMLNode {
        let tag = element.tag ?? "div"
        
        let attributes = element.attributes.reduce(into: [String: String]()) { result, attribute in
            result[attribute.key] = attribute.value
        }
        
        let children: [HTMLChild] = try element.childNodes(ofTypes: [.Element, .Text])
            .compactMap { node -> HTMLChild? in
                if node.type == .Text {
                    let text = node.stringValue
                    return text.isEmpty ? nil : .trimmingText(text)
                } else if let childElement = node.toElement() {
                    if childElement.tag == "br" {
                        return .newLine
                    }
                    return .node(try elementToHTMLNode(element: childElement))
                }
                return nil
            }
        
        return HTMLNode(tag: tag, attributes: attributes, children: children)
    }
    
    private func createErrorNode(_ message: String) -> HTMLNode {
        HTMLNode(tag: "div", attributes: [:], children: [.text(message)])
    }
}
#endif

// MARK: - Cross-Platform WebView Representable
#if !os(iOS)
/// Type alias for the correct view representable protocol based on the platform.
private typealias ViewRepresentable = NSViewRepresentable

/// The WKWebView implementation wrapped in a ViewRepresentable for macOS.
private struct WebViewRepresentable: ViewRepresentable {
    @Environment(NavigationModel.self) private var navigationModel

    let html: String
    let courseID: Course.ID?

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator {
            await navigationModel.handleURLSelection(result: $0, courseID: courseID)
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let onDestinationLink: (CanvasURLService.URLServiceResult) async -> Void

        init(onDestinationLink: @escaping (CanvasURLService.URLServiceResult) async -> Void) {
            self.onDestinationLink = onDestinationLink
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
                Task {
                    if let potentialDestination = CanvasURLService.determineNavigationDestination(from: url) {
                        await onDestinationLink(potentialDestination)
                    } else {
                        NSWorkspace.shared.open(url)
                    }
                }
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}
#endif
