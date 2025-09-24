//
//  PageView.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 2/25/25.
//

import SwiftUI

struct PageView: View {
    let page: Page

    var body: some View {
        ZStack {
            if let htmlContent = page.body, !htmlContent.isEmpty {
                HTMLView(html: htmlContent, courseID: page.courseID)
                    .pickedItem(page)
            } else {
                ContentUnavailableView("No pages available", systemImage: "exclamationmark.bubble.fill")
            }
        }
        .navigationTitle(page.title ?? "Untitled")
    }
}
