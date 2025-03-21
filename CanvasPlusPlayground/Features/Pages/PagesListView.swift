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

    @State private var selectedPage: Page?

    init(courseId: String) {
        _pagesManager = State(initialValue: PagesManager(courseID: courseId))
    }

    var body: some View {
        List(pagesManager.pages, id: \.id, selection: $selectedPage) { page in
            NavigationLink(value: page) {
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
        .navigationDestination(item: $selectedPage) { page in
            PageView(page: page)
        }
        .pickedItem(selectedPage)
    }

    private func loadPages() async {
        isLoadingPages = true
        await pagesManager.fetchPages()
        isLoadingPages = false
    }
}
