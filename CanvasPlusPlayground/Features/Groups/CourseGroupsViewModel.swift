//
//  GroupsViewModel.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 3/23/25.
//

import Foundation

@Observable
class CourseGroupsViewModel {
    let courseId: String
    var groups = Set<CanvasGroup>()

    var displayedGroups: [CanvasGroup] {
        Array(groups)
    }

    init(courseId: String) {
        self.courseId = courseId
    }

    func fetchGroups() async {
        let req = CanvasRequest.getCourseGroups(courseId: courseId)

        do {
            try await CanvasService.shared.loadAndSync(
                req,
                onCacheReceive: { [weak self] in
                    guard let groups = $0 else { return }
                    self?.insertGroups(groups)
                },
                loadingMethod: .all(onNewPage: { [weak self] in
                    self?.insertGroups($0)
                })
            )
        } catch {
            LoggerService.main.error("[CourseGroupsViewModel] Group fetch failed: \(error)")
        }
    }

    func insertGroups(_ groups: [CanvasGroup]) {
        DispatchQueue.main.async {
            self.groups.formUnion(groups)
        }
    }
}
