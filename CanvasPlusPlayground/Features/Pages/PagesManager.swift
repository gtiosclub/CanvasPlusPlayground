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
    private var pagesSet = Set<Page>()

    var sortOption: GetPagesRequest.SortOption = .title
    var sortOrder: GetPagesRequest.OrderOption = .ascending

    var pages: [Page] {
        Page.sortedPages(Array(pagesSet), by: sortOption, order: sortOrder)
    }

    init(courseID: String) {
        self.courseID = courseID
    }

    func fetchPages() async {
        if AppEnvironment.isSandbox {
            setPages(SandboxData.dummyPages)
            return
        }
        let request = CanvasRequest.getPages(courseId: self.courseID)
        do {
            let fetchedPages = try await CanvasService.shared.loadAndSync(
                request,
                onCacheReceive: { cachedPages in
                    guard let cachedPages else { return }
                    Task { @MainActor in
                        self.setPages(cachedPages)
                    }
                },
                loadingMethod: .all(onNewPage: { newPages in
                    Task { @MainActor in
                        self.appendPages(newPages)
                    }
                })
            )
            Task { @MainActor in
                self.setPages(fetchedPages)
            }
        } catch {
            LoggerService.main.error("Failed to fetch pages: \(error)")
        }
    }

    func setPages(_ pages: [Page]) {
        self.pagesSet = Set(pages)
    }

    func appendPages(_ newPages: [Page]) {
        self.pagesSet.formUnion(newPages)
    }
}
