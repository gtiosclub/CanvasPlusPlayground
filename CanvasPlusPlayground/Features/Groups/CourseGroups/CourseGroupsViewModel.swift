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
    var groups = [CanvasGroup]()

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
            LoggerService.main.error("[CourseGroupsViewModel] Groups fetch failed: \(error)")
        }
    }

    func insertGroups(_ groups: [CanvasGroup]) {
        let newGroups = groups.filter {
            !self.groups.contains($0)
        }

        DispatchQueue.main.async {
            self.groups.append(contentsOf: newGroups)
        }
    }
}
