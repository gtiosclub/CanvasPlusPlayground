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
            let user: User = try await CanvasService.shared.loadAndSync(CanvasRequest.getUser())[0]
            currentUser = user
        } catch {
            print("Error fetching current user: \(error)")
        }

        do {
            let profile: Profile = try await CanvasService.shared.loadAndSync(CanvasRequest.getUserProfile())[0]
            currentProfile = profile
        } catch {
            print("Error fetching current user profile: \(error)")
        }

        print("Current user: \(currentUser?.name ?? "")")
        print("Current user profile: \(currentProfile?.primaryEmail ?? "")")
    }

    func getProfile(for id: User.ID) async -> Profile? {
        do {
            let profile: Profile = try await CanvasService.shared.loadAndSync(CanvasRequest.getUserProfile(userId: id))[0]

            return profile
        } catch {
            print("Error fetching user profile: \(error)")
        }

        return nil
    }
}
