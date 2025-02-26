//
//  PagesManager.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 2/25/25.
//

import Foundation

@Observable
class PagesManager {
    private let courseID: String
    var pages = [Page]()

    init(courseID: String) {
        self.courseID = courseID
    }

    func fetchPages() async {
        let request = CanvasRequest.getPages(courseId: self.courseID)
        do {
            let fetchedPages = try await CanvasService.shared.loadAndSync(request)
            self.pages = fetchedPages
        } catch {
            LoggerService.main.error("Failed to fetch pages: \(error)")
        }
    }
}
