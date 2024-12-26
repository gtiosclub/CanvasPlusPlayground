//
//  ProfileManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/18/24.
//

import SwiftUI

@Observable
class ProfileManager {
    private(set) var currentUser: UserAPI?
    private(set) var currentProfile: ProfileAPI?

    // MARK: - Methods
    func getCurrentUserAndProfile() async {
        do {
            let user: UserAPI = try await CanvasService.shared.fetch(CanvasRequest.getUser())[0]
            currentUser = user
        } catch {
            print("Error fetching current user: \(error)")
        }

        do {
            let profile: ProfileAPI = try await CanvasService.shared.fetch(CanvasRequest.getUserProfile())[0]
            currentProfile = profile
        } catch {
            print("Error fetching current user profile: \(error)")
        }

        print("Current user: \(currentUser?.name ?? "")")
        print("Current user profile: \(currentProfile?.primary_email ?? "")")
    }
}
