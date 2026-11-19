//
//  AgentModelRouter.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation
import FoundationModels

/// Picks a provider for each task: the best tier the task allows that can run right now,
/// falling back to `.none` so every feature still works without a model.
@available(iOS 26.0, macOS 26.0, *)
struct AgentModelRouter: Sendable {
    var onDevice: any AgentModelProvider
    /// Stands in for the on-device model when it isn't available (simulators, devices
    /// without Apple Intelligence). `nil` in production.
    var fallbackFake: (any AgentModelProvider)?
    /// Tier 2. Only used when a task allows `.cloud`, which features do only after the student
    /// chooses cloud for that request. Unavailable unless Cloud Intelligence is set up.
    var cloud: (any AgentModelProvider)?
    var noModel: any AgentModelProvider

    init(
        onDevice: any AgentModelProvider = OnDeviceModelProvider(),
        fallbackFake: (any AgentModelProvider)? = nil,
        cloud: (any AgentModelProvider)? = GeminiProvider(),
        noModel: any AgentModelProvider = NoModelProvider()
    ) {
        self.onDevice = onDevice
        self.fallbackFake = fallbackFake
        self.cloud = cloud
        self.noModel = noModel
    }

    /// - Parameter allowed: tiers the task may use. On-device wins over cloud when both are
    ///   allowed and available, since it's private and free.
    func provider(allowing allowed: Set<AgentTier> = [.onDevice]) -> any AgentModelProvider {
        if allowed.contains(.onDevice) {
            if onDevice.isAvailable {
                return onDevice
            } else if let fallbackFake, fallbackFake.isAvailable {
                return fallbackFake
            }
        }

        if allowed.contains(.cloud), let cloud, cloud.isAvailable {
            return cloud
        }

        return noModel
    }
}
