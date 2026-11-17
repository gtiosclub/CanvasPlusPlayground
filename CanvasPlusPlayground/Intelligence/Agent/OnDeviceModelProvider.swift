//
//  OnDeviceModelProvider.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation
import FoundationModels

/// Tier 1: Apple's on-device model through `LanguageModelSession`.
///
/// Each call uses a fresh session, so calls don't leak context into each other and the
/// ~4k-token window starts empty every time. `IntelligenceSupport.modelAvailability` is the gate.
@available(iOS 26.0, macOS 26.0, *)
struct OnDeviceModelProvider: AgentModelProvider {
    let tier = AgentTier.onDevice

    var isAvailable: Bool {
        IntelligenceSupport.isModelAvailable
    }

    func respond<Output: Generable>(
        to prompt: AgentPrompt,
        tools: [any Tool],
        generating type: Output.Type
    ) async throws -> AgentResponse<Output> {
        guard isAvailable else {
            throw AgentModelError.unavailable(IntelligenceSupport.modelAvailabilityDescription)
        }

        let session = LanguageModelSession(tools: tools, instructions: prompt.instructions)

        do {
            let response = try await session.respond(
                to: prompt.text,
                generating: type,
                options: GenerationOptions(temperature: prompt.temperature)
            )

            return AgentResponse(
                content: response.content,
                tier: tier,
                toolCalls: Self.toolCallNames(in: session.transcript)
            )
        } catch let error as LanguageModelSession.GenerationError {
            throw Self.agentError(for: error)
        }
    }

    static func toolCallNames(in transcript: Transcript) -> [String] {
        transcript.flatMap { entry -> [String] in
            guard case .toolCalls(let calls) = entry else { return [] }
            return calls.map(\.toolName)
        }
    }

    static func agentError(for error: LanguageModelSession.GenerationError) -> AgentModelError {
        switch error {
        case .exceededContextWindowSize:
            .contextWindowExceeded
        case .guardrailViolation:
            .guardrailViolation
        case .refusal:
            .refused
        case .rateLimited, .concurrentRequests:
            .rateLimited
        case .decodingFailure:
            .decodingFailed
        case .assetsUnavailable:
            .unavailable("The on-device model isn't downloaded yet. Try again later.")
        case .unsupportedLanguageOrLocale:
            .unavailable("Apple Intelligence doesn't support this language yet.")
        default:
            .other(error.localizedDescription)
        }
    }
}
