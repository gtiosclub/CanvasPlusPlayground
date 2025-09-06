//
//  WikiFrontPage.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/25.
//

import SwiftUI

struct WikiFrontPage: View {
    @State private var page: Page?
    @State private var unableToLoad: Bool = false

    let course: Course

    var body: some View {
        Group {
            if let page {
                PageView(page: page)
            } else if unableToLoad {
                ContentUnavailableView(
                    "Unable to load page",
                    systemImage: "exclamationmark.triangle.fill"
                )
            } else {
                ProgressView("Loading...")
            }
        }
        .task {
            do {
                try await getFrontPage()
            } catch {
                unableToLoad = true
            }
        }
    }

    private func getFrontPage() async throws {
        let request = CanvasRequest.getCourseFrontPage(courseID: course.id)

        let frontPage = try await CanvasService.shared
            .loadAndSync(request, onCacheReceive: { pages in
                self.page = pages?.first
            })

        self.page = frontPage.first
    }
}
