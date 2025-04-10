//
//  CourseTabsView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/15/24.
//

import SwiftUI
import WebKit

struct CourseTabsView: View {
    @Environment(CourseTabsManager.self) private var tabsManager

    let course: Course
    let baseURL: String

    @State private var selectedURL: URL?
    @State private var showWebView = false

    init(course: Course) {
        self.course = course
        self.baseURL = "https://gatech.instructure.com/courses/\(String(course.id))"
    }

    var body: some View {
        List(tabsManager.tabLabels, id: \.self) { label in
            Button(label) {
                let lowerCaseLabel = label.lowercased()
                let urlString = (lowerCaseLabel == "home") ? baseURL : "\(baseURL)/\(lowerCaseLabel)"

                if let url = URL(string: urlString) {
                    selectedURL = url
                    showWebView = true
                }
            }
        }
        .navigationTitle("Tabs")
        .sheet(isPresented: $showWebView) {
            NavigationStack {
                Group {
                    if let url = selectedURL {
                        WebView(url: url)
                    }
                }
               .toolbar {
                   Button("Close") {
                       showWebView = false
                   }
               }
            }
            .frame(minWidth: 800, minHeight: 600)
        }
    }
}

#if os(iOS)
typealias PlatformRepresentable = UIViewRepresentable
#else
typealias PlatformRepresentable = NSViewRepresentable
#endif

struct WebView: PlatformRepresentable {
    let url: URL

#if os(iOS)
    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        loadRequest(webView)
    }
#else
    func makeNSView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        loadRequest(webView)
    }
#endif

    private func loadRequest(_ webView: WKWebView) {
        var request = URLRequest(url: url)

        // TODO: pass auth token, not accessToken
        request.setValue("Bearer \(StorageKeys.accessTokenValue)", forHTTPHeaderField: "Authorization")
        webView.load(request)
    }
}
