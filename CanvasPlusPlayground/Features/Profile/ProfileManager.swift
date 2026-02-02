//
//  ProfileManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/18/24.
//

import SwiftUI

@Observable
class ProfileManager {
    private(set) var currentUser: User?
    private(set) var currentProfile: Profile?

    // MARK: - Methods
    func getCurrentUserAndProfile() async {
        do {
            let user: User = try await CanvasService.shared.loadAndSync(CanvasRequest.getUser(), onCacheReceive: { users in
                currentUser = users?.first
            })[0]

            currentUser = user
        } catch {
            LoggerService.main.error("Error fetching current user: \(error)")
        }

        do {
            let profile: Profile = try await CanvasService.shared.loadAndSync(CanvasRequest.getUserProfile(), onCacheReceive: { profiles in
                currentProfile = profiles?.first
            })[0]

            currentProfile = profile
        } catch {
            LoggerService.main.error("Error fetching current user profile: \(error)")
        }

        LoggerService.main.debug("Current user: \(self.currentUser?.name ?? "")")
        LoggerService.main.debug("Current user profile: \(self.currentProfile?.primaryEmail ?? "")")
    }

    func getProfile(for id: User.ID) async -> Profile? {
        do {
            return try await CanvasService.shared.loadAndSync(CanvasRequest.getUserProfile(userId: id))[0] as Profile
        } catch {
            LoggerService.main.error("Error fetching user profile: \(error)")
        }

        return nil
    }

    /// Sets user and profile for sandbox mode. Only used when AppEnvironment.isSandbox is true.
    func setSandboxUserAndProfile(user: User, profile: Profile) {
        currentUser = user
        currentProfile = profile
    }
}
