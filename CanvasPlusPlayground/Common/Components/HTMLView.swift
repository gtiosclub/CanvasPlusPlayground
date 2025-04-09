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
    #else
    func updateNSView(_ nsView: WKWebView, context: Context) {
        updateView(nsView, context: context)
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
        view.loadHTMLString(html, baseURL: nil)
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
                        UIApplication.shared.open(url)
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
