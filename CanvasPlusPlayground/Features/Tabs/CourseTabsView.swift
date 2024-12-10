//
//  CourseTabsView.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/15/24.
//

import SwiftUI
import WebKit

#if os(iOS)
typealias PlatformRepresentable = UIViewRepresentable
#else
typealias PlatformRepresentable = NSViewRepresentable
#endif

struct WebView: PlatformRepresentable {
    let url: URL

    #if os(iOS)
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        loadRequest(webView)
    }
    #else
    func makeNSView(context: Context) -> WKWebView {
        return WKWebView()
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

struct CourseTabsView: View {
    let course: Course
    let base_url: String
    @State var tabsManager: CourseTabsManager
    
    @State private var selectedURL: URL?
    @State private var showWebView = false

    init(course: Course) {
        self.course = course
        self.tabsManager = CourseTabsManager(course: course)
        self.base_url = "https://gatech.instructure.com/courses/\(String(course.id))"
    }
    
    var body: some View {
        List(tabsManager.tabLabels, id: \.self) { label in
            Button(label) {
                let lower_case_label = label.lowercased()
                let urlString = (lower_case_label == "home") ? base_url : "\(base_url)/\(lower_case_label)"
                
                if let url = URL(string: urlString) {
                    selectedURL = url
                    showWebView = true
                }
            }
        }
        .navigationTitle("Tabs")
        .task {
            await tabsManager.fetchTabs()
        }
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

