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
    var noModel: any AgentModelProvider

    init(
        onDevice: any AgentModelProvider = OnDeviceModelProvider(),
        fallbackFake: (any AgentModelProvider)? = nil,
        noModel: any AgentModelProvider = NoModelProvider()
    ) {
        self.onDevice = onDevice
        self.fallbackFake = fallbackFake
        self.noModel = noModel
    }

    /// - Parameter allowed: tiers the task may use. Cloud is ignored until #604 adds a provider
    ///   and the student opts in.
    func provider(allowing allowed: Set<AgentTier> = [.onDevice]) -> any AgentModelProvider {
        if allowed.contains(.onDevice) {
            if onDevice.isAvailable {
                return onDevice
            } else if let fallbackFake, fallbackFake.isAvailable {
                return fallbackFake
            }
        }

        return noModel
    }
}
