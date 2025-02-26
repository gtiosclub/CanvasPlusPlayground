//
//  PagesListView.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 2/22/25.
//

import SwiftUI

struct PagesListView: View {
    @State private var pagesManager: PagesManager
    @State private var isLoadingPages: Bool = true

    init(courseId: String) {
        self.pagesManager = PagesManager(courseID: courseId)
    }

    var body: some View {
        NavigationStack {
            List(pagesManager.pages, id: \.id) { page in
                NavigationLink {
                    PageView(page: page)
                } label: {
                    Text(page.title ?? "Untitled")
                }
            }
            .overlay {
                if pagesManager.pages.isEmpty {
                    ContentUnavailableView("No pages available", systemImage: "exclamationmark.bubble.fill")
                } else {
                    EmptyView()
                }
            }
            .task {
                await loadPages()
            }
            .refreshable {
                await loadPages()
            }
            .statusToolbarItem(
                "Pages",
                isVisible: isLoadingPages
            )
            .navigationTitle("Pages")
        }
    }

    private func loadPages() async {
        isLoadingPages = true
        await pagesManager.fetchPages()
        isLoadingPages = false
    }
}
