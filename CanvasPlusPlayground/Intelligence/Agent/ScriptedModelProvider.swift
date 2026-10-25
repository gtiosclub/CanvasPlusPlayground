//
//  ScriptedModelProvider.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation
import FoundationModels

/// A fake model that replays a script, for working on agent features in the simulator or on a
/// device without Apple Intelligence.
///
/// Each step can call tools the way the model would (by name, with JSON arguments), so the real
/// tools run against real data. Then it returns scripted JSON decoded into the requested
/// `@Generable` type, the same path a cloud response takes.
@available(iOS 26.0, macOS 26.0, *)
actor ScriptedModelProvider: AgentModelProvider {
    enum Step: Sendable {
        /// Call `toolCalls` in order, then answer with `json`.
        case respond(json: String, toolCalls: [ToolCall] = [])
        /// Throw this error, e.g. to test a feature's fallback.
        case fail(AgentModelError)
    }

    struct ToolCall: Sendable {
        let toolName: String
        let argumentsJSON: String

        init(_ toolName: String, arguments argumentsJSON: String = "{}") {
            self.toolName = toolName
            self.argumentsJSON = argumentsJSON
        }
    }

    nonisolated let tier = AgentTier.onDevice
    nonisolated let isAvailable = true

    private var steps: [Step]
    private let repeatsLastStep: Bool

    /// Every prompt this provider was asked, for checking what a feature sent.
    private(set) var receivedPrompts: [AgentPrompt] = []

    /// - Parameter repeatsLastStep: keep answering with the last step instead of throwing
    ///   `scriptExhausted`. Handy for screens that call the model on every refresh.
    init(steps: [Step], repeatsLastStep: Bool = false) {
        self.steps = steps
        self.repeatsLastStep = repeatsLastStep
    }

    func respond<Output: Generable>(
        to prompt: AgentPrompt,
        tools: [any Tool],
        generating type: Output.Type
    ) async throws -> AgentResponse<Output> {
        receivedPrompts.append(prompt)

        guard let step = steps.first else {
            throw AgentModelError.scriptExhausted
        }
        if steps.count > 1 || !repeatsLastStep {
            steps.removeFirst()
        }

        switch step {
        case .fail(let error):
            throw error
        case let .respond(json, toolCalls):
            for call in toolCalls {
                guard let tool = tools.first(where: { $0.name == call.toolName }) else {
                    throw AgentModelError.toolNotFound(call.toolName)
                }
                try await Self.invoke(tool, argumentsJSON: call.argumentsJSON)
            }

            do {
                let content = try Output(GeneratedContent(json: json))
                return AgentResponse(content: content, tier: tier, toolCalls: toolCalls.map(\.toolName))
            } catch {
                throw AgentModelError.decodingFailed
            }
        }
    }

    private static func invoke(_ tool: any Tool, argumentsJSON: String) async throws {
        try await call(tool, argumentsJSON: argumentsJSON)
    }

    private static func call<T: Tool>(_ tool: T, argumentsJSON: String) async throws {
        let arguments = try T.Arguments(GeneratedContent(json: argumentsJSON))
        _ = try await tool.call(arguments: arguments)
    }
}
