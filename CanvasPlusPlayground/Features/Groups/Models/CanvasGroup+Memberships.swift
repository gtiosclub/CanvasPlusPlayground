//
//  CanvasGroup+Memberships.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 3/29/25.
//

// MARK: Memberships
extension CanvasGroup {
    @MainActor
    func leaveGroup() async throws {
        isLoadingMembership = true
        defer { isLoadingMembership = false }

        let req = CanvasRequest.leaveGroup(groupId: id, via: .memberships(membershipId: "self"))

        try await CanvasService.shared.fetch(req)

        currUserStatus = nil // leaving should have succeeded if no error was thrown, so we assume `left` state

        LoggerService.main.debug(
            """
            [GroupsListView] Group leave for \(self.name) succeeded:
            \(self.currUserStatus?.rawValue ?? "nil"), \(self.availableAction?.rawValue ?? "nil")
            """
        )
    }

    @MainActor
    func acceptInvite() async throws {
        isLoadingMembership = true
        defer { isLoadingMembership = false }

        let req = CanvasRequest.updateGroupMembership(groupId: id, via: .memberships(membershipId: "self"))

        let membershipRes = try await CanvasService.shared.syncWithAPI(req)
        let membership = membershipRes[0]

        self.currUserStatus = membership.workflowState

        LoggerService.main.debug(
            """
            [GroupsListView] Group invite accept for \(self.name) succeeded:
            \(self.currUserStatus?.rawValue ?? "nil"), \(self.availableAction?.rawValue ?? "nil")
            """
        )
    }

    @MainActor
    func joinGroup() async throws {
        isLoadingMembership = true
        defer { isLoadingMembership = false }

        let req = CanvasRequest.createGroupMembership(groupId: self.id)

        let membershipRes = try await CanvasService.shared.syncWithAPI(req)
        let membership = membershipRes[0]

        membership.tag = "\(self.id)/self"

        self.currUserStatus = membership.workflowState

        LoggerService.main.debug(
            """
            [GroupsListView] Group join request for \(self.name) succeeded:
            \(self.currUserStatus?.rawValue ?? "nil"), \(self.availableAction?.rawValue ?? "nil")
            """
        )
    }

    @MainActor
    func fetchMembershipState() async throws {
        isLoadingMembership = true
        defer { isLoadingMembership = false }

        let req = CanvasRequest.getSingleGroupMembership(groupId: self.id, via: .users(userId: "self"))
        do {
            let membershipRes = try await CanvasService.shared.syncWithAPI(req)
            let membership = membershipRes[0]

            self.currUserStatus = membership.workflowState
            LoggerService.main.debug(
                """
                [GroupsListView] Membership state fetch for \(self.name) succeeded:
                \(self.currUserStatus?.rawValue ?? "nil"), \(self.availableAction?.rawValue ?? "nil")
                """
            )
        } catch {
            // If 404 (not found) -> means user is not in group, so we reset status.
            if let error = error as? HTTPStatusCode, error == .notFound {
                self.currUserStatus = nil
                LoggerService.main.error("[GroupsListView] Membership wansn't found. User is not part of group.")
            } else {
                LoggerService.main.error("[GroupsListView] Membership state fetch failed: \(error)")
                throw error
            }
        }
    }
}
