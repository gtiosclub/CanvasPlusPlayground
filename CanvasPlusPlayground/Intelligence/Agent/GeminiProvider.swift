//
//  GeminiProvider.swift
//  CanvasPlusPlayground
//

import Foundation
import FoundationModels

/// Tier 2: Gemini with the student's own API key. Off unless they've turned it on, accepted the
/// consent screen and added a key; every request goes through `CloudEgress`.
///
/// Tools are offered as Gemini function declarations built from the same `GenerationSchema` the
/// on-device model uses. The model may call them for a few rounds; then one last call asks for
/// the answer as JSON matching the output type's schema (Gemini doesn't reliably combine function
/// calling and a response schema in one call).
@available(iOS 26.0, macOS 26.0, *)
struct GeminiProvider: AgentModelProvider {
    /// Tool-calling rounds before the provider stops offering tools and asks for the answer.
    static let maxToolRounds = 4

    let tier = AgentTier.cloud
    let egress: CloudEgress

    init(egress: CloudEgress = CloudEgress()) {
        self.egress = egress
    }

    var isAvailable: Bool {
        egress.settings.isReady
    }

    func respond<Output: Generable>(
        to prompt: AgentPrompt,
        tools: [any Tool],
        generating type: Output.Type
    ) async throws -> AgentResponse<Output> {
        do {
            return try await run(prompt, tools: tools, generating: type)
        } catch let error as CloudEgressError {
            throw error.agentError
        }
    }

    private func run<Output: Generable>(
        _ prompt: AgentPrompt,
        tools: [any Tool],
        generating type: Output.Type
    ) async throws -> AgentResponse<Output> {
        // Fail before any work if the request couldn't be sent anyway.
        _ = try egress.authorize(courseIDs: prompt.courseIDs)

        let system = GeminiAPI.Content(role: nil, parts: [GeminiAPI.Part(text: prompt.instructions)])
        let outputConfig = GeminiAPI.GenerationConfig(
            temperature: prompt.temperature,
            responseMimeType: "application/json",
            responseJsonSchema: try Self.schema(Output.generationSchema)
        )

        var contents = [GeminiAPI.Content.user(prompt.text)]
        var toolCalls: [String] = []
        // Courses whose records a tool sent back. The final request has to be allowed for them too.
        var courseIDs = prompt.courseIDs

        if !tools.isEmpty {
            let declarations = try tools.map(Self.declaration)

            for _ in 0..<Self.maxToolRounds {
                let response = try await egress.generateContent(
                    GeminiAPI.Request(
                        systemInstruction: system,
                        contents: contents,
                        tools: [GeminiAPI.ToolSet(functionDeclarations: declarations)],
                        generationConfig: GeminiAPI.GenerationConfig(temperature: prompt.temperature)
                    ),
                    courseIDs: courseIDs
                )
                try Self.checkNotBlocked(response)

                let calls = response.parts.compactMap(\.functionCall)
                guard !calls.isEmpty else { break }

                contents.append(GeminiAPI.Content(role: "model", parts: response.parts))

                var results: [GeminiAPI.Part] = []
                for call in calls {
                    toolCalls.append(call.name)
                    let result = await invoke(call, in: tools, allowedCourses: egress.settings.optedInCourseIDs)
                    courseIDs.formUnion(result.courseIDs)
                    results.append(GeminiAPI.Part(functionResponse: .init(name: call.name, response: result.response)))
                }
                contents.append(GeminiAPI.Content(role: "user", parts: results))
            }

            contents.append(.user("Now give your final answer as JSON matching the response schema."))
        }

        let response = try await egress.generateContent(
            GeminiAPI.Request(systemInstruction: system, contents: contents, tools: nil, generationConfig: outputConfig),
            courseIDs: courseIDs
        )
        try Self.checkNotBlocked(response)

        let content = try AgentOutputSchema.decode(Output.self, from: response.text)
        return AgentResponse(content: content, tier: tier, toolCalls: toolCalls)
    }

    // MARK: Tools

    private struct ToolResult {
        let response: JSONValue
        let courseIDs: Set<String>
    }

    /// Runs one function call. Errors go back to the model as `{"error": …}` rather than ending the run.
    /// Evidence from courses that aren't shared with the cloud is removed before it's returned.
    private func invoke(_ call: GeminiAPI.FunctionCall, in tools: [any Tool], allowedCourses: Set<String>) async -> ToolResult {
        guard let tool = tools.first(where: { $0.name == call.name }) else {
            return ToolResult(response: .object(["error": .string("No tool named \(call.name).")]), courseIDs: [])
        }

        do {
            let output = try await Self.call(tool, argumentsJSON: (call.args ?? .object([:])).jsonString)
            let text: String
            var courseIDs: Set<String> = []

            if let bundle = output as? EvidenceBundle {
                let shared = bundle.evidence.filter { $0.ref.courseID.map(allowedCourses.contains) ?? true }
                courseIDs = Set(shared.compactMap(\.ref.courseID))
                let withheld = bundle.evidence.count - shared.count
                text = EvidenceBundle(evidence: shared).promptText
                    + (withheld > 0 ? "\n(\(withheld) more from courses not shared with the cloud.)" : "")
            } else if let string = output as? String {
                text = string
            } else {
                text = String(describing: output)
            }

            return ToolResult(response: .object(["result": .string(text)]), courseIDs: courseIDs)
        } catch {
            return ToolResult(response: .object(["error": .string(error.localizedDescription)]), courseIDs: [])
        }
    }

    private static func call(_ tool: any Tool, argumentsJSON: String) async throws -> Any {
        try await callTyped(tool, argumentsJSON: argumentsJSON)
    }

    private static func callTyped<T: Tool>(_ tool: T, argumentsJSON: String) async throws -> Any {
        let arguments = try T.Arguments(GeneratedContent(json: argumentsJSON))
        return try await tool.call(arguments: arguments)
    }

    static func declaration(for tool: any Tool) throws -> GeminiAPI.FunctionDeclaration {
        GeminiAPI.FunctionDeclaration(
            name: tool.name,
            description: tool.description,
            parametersJsonSchema: try schema(tool.parameters)
        )
    }

    /// JSON Schema for Gemini, with every `$ref` replaced by its definition. FoundationModels puts
    /// nested types in `$defs`; Gemini's schema support is a subset, so a flat schema is safest.
    static func schema(_ schema: GenerationSchema) throws -> JSONValue {
        inliningReferences(try JSONValue(jsonData: AgentOutputSchema.jsonSchema(schema)))
    }

    static func inliningReferences(_ schema: JSONValue) -> JSONValue {
        guard case .object(var root) = schema else { return schema }
        var definitions: [String: JSONValue] = [:]
        if case .object(let defs)? = root.removeValue(forKey: "$defs") { definitions = defs }

        func resolve(_ value: JSONValue, depth: Int) -> JSONValue {
            switch value {
            case .object(let object):
                if case .string(let ref)? = object["$ref"], ref.hasPrefix("#/$defs/"), depth < 8,
                   let definition = definitions[String(ref.dropFirst("#/$defs/".count))] {
                    return resolve(definition, depth: depth + 1)
                }
                return .object(object.filter { $0.key != "title" }.mapValues { resolve($0, depth: depth) })
            case .array(let items):
                return .array(items.map { resolve($0, depth: depth) })
            default:
                return value
            }
        }

        return resolve(.object(root), depth: 0)
    }

    private static func checkNotBlocked(_ response: GeminiAPI.Response) throws {
        if response.promptFeedback?.blockReason != nil {
            throw AgentModelError.guardrailViolation
        }
        if response.candidates?.first?.finishReason == "SAFETY" {
            throw AgentModelError.guardrailViolation
        }
    }
}
