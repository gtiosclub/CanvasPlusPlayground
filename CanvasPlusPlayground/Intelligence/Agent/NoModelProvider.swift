//
//  NoModelProvider.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation
import FoundationModels

/// Tier 0: there's no model to ask. `respond` always throws, so a feature handed this
/// provider knows to show its pure-Swift version instead.
@available(iOS 26.0, macOS 26.0, *)
struct NoModelProvider: AgentModelProvider {
    let tier = AgentTier.none
    let isAvailable = true

    func respond<Output: Generable>(
        to prompt: AgentPrompt,
        tools: [any Tool],
        generating type: Output.Type
    ) async throws -> AgentResponse<Output> {
        throw AgentModelError.unavailable("No model is available on this device.")
    }
}
