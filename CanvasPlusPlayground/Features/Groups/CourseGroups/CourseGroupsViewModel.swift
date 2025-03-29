//
//  GroupsViewModel.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 3/23/25.
//

import Foundation

@Observable
class CourseGroupsViewModel {
    var groups = [CanvasGroup]()

    var groupsDisplayed: [CanvasGroup] {
        groups
            .sorted { // sort priority: (1) category name (2) group name
                guard $0.groupCategoryName != $1.groupCategoryName else {
                    return $0.name < $1.name
                }
                return ($0.groupCategoryName ?? "") < ($1.groupCategoryName ?? "")
            }
    }

    func fetchGroups(for courseId: String) async {
        let req = CanvasRequest.getCourseGroups(courseId: courseId, perPage: 30)

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

    func leaveGroup(_ group: CanvasGroup) async {

    }

    func joinGroup(_ group: CanvasGroup) async {
        
    }

    func fetchAllGroups() async {
        // TODO: in the future when implementing generic Groups tab
    }

    private func insertGroups(_ groups: [CanvasGroup]) {
        let newGroups = groups.filter {
            !self.groups.contains($0)
        }

        DispatchQueue.main.async {
            self.groups.append(contentsOf: newGroups)
        }
    }
}
