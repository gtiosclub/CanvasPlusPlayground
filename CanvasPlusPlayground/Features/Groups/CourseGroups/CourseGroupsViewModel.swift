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
    var searchText: String = ""
    var groupsDisplayed: [CanvasGroup] {
        groups
            .filter({ group in
                guard !searchText.isEmpty else { return true }
                if group.name.localizedCaseInsensitiveContains(searchText) { return true }
                return group.users?.contains { $0.name.localizedCaseInsensitiveContains(searchText) } ?? false
            })
            .sorted { // sort priority: (1) category name (2) group name
                guard $0.groupCategoryId != $1.groupCategoryId else {
                    return $0.name < $1.name
                }
                return ($0.groupCategoryId ?? -1) < ($1.groupCategoryId ?? -1)
            }
    }

    func fetchGroups(for courseId: String) async {
        let req = CanvasRequest.getCourseGroups(courseId: courseId, perPage: 15)

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

    func fetchAllGroupMembershipsFor(categoryId: Int, excluding groupId: String?) async throws {
        await withThrowingTaskGroup(of: Void.self, body: { taskGroup in
            for group in groupsDisplayed where group.groupCategoryId == categoryId && group.id != groupId {
                taskGroup.addTask {
                    try await group.fetchMembershipState()
                    LoggerService.main.debug("[CourseGroupsViewModel] Leaving group: \(group.name)")
                }
            }
        })
    }

    /// Whether joining this group is classified as a switch - joined groups from this category are left.
    /// Only use this with groups that have join status.
    func canOnlySwitch(to group: CanvasGroup) -> Bool {
        if group.allowsMultipleMemberships ?? false {
            return false // if multiple memberships's are allowed, switch isn't necessary
        }

        let groupsInCategory = groups.filter { $0.groupCategoryId == group.groupCategoryId && $0.id != group.id }

        // If another group in this category has this user
        return groupsInCategory.contains(where: {
            $0.currUserStatus == .accepted || $0.currUserStatus == .requested
        })
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
