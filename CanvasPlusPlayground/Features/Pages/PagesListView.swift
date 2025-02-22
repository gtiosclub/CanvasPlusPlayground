//
//  PagesList.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 2/21/25.
//

import SwiftUI

struct PagesListView: View {
    var body: some View {
        Button(action: {
            Task {
                await fetchPages()
            }
        }) {
            Text("Click")
        }
    }
}

func fetchPages() async {
    do {
        let pages: [Page] = try await CanvasService.shared.loadAndSync(
            CanvasRequest.getPages(courseId: "268514")
        )
        print("Fetched Pages: \(pages.map { $0.body })")

    } catch {
        print("Failed to fetch pages: \(error)")
    }
}
