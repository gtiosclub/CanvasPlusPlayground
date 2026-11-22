//
//  CloudProviderTests.swift
//  CanvasPlusPlaygroundTests
//

import Foundation
import FoundationModels
import Testing
@testable import CanvasPlusPlayground

// MARK: - Redaction

struct EgressRedactorTests {
    let redactor = EgressRedactor(names: ["Jane Smith", "Bob", "Mary Ann Lee", "  José   García "])

    @Test(arguments: [
        ("Email jane.smith@gatech.edu about it", "Email [email] about it"),
        ("Call (404) 555-0100 or 404.555.0199", "Call [phone] or [phone]"),
        ("Text +1 404 555 0100", "Text [phone]"),
        ("Ask Jane Smith in office hours", "Ask [person] in office hours"),
        ("ask JANE  SMITH", "ask [person]"),
        ("Mary Ann Lee posted", "[person] posted"),
        ("José García's notes", "[person]'s notes"),
    ])
    func removes(_ input: String, expected: String) {
        #expect(redactor.redact(input) == expected)
    }

    @Test(arguments: [
        "Bob the builder",              // single names are ignored
        "Jane Smithson is a student",   // no partial-word matches
        "Course 4045550100 assignment 1234567", // bare ids aren't phone numbers
        "Due Friday at 11:59 PM",
    ])
    func keeps(_ input: String) {
        #expect(redactor.redact(input) == input)
    }

    @Test func reordersSortableNames() {
        #expect(EgressRedactor.reordered("Smith, Jane") == "Jane Smith")
        #expect(EgressRedactor.reordered("Jane Smith") == "Jane Smith")
    }

    @Test func redactsEveryTextFieldOfARequest() {
        let request = GeminiAPI.Request(
            systemInstruction: .init(role: nil, parts: [.init(text: "Never email jane@x.com")]),
            contents: [
                .user("What did Jane Smith say?"),
                .init(role: "model", parts: [.init(functionCall: .init(name: "lookup", args: .object(["who": .string("Jane Smith")])))]),
                .init(role: "user", parts: [.init(functionResponse: .init(name: "lookup", response: .object(["result": .array([.string("jane@x.com")])])))])
            ]
        )

        let redacted = request.redacted(with: redactor.redact)
        let json = String(decoding: try! JSONEncoder().encode(redacted), as: UTF8.self)
        #expect(!json.contains("Jane"))
        #expect(!json.contains("jane@"))
        #expect(json.contains("lookup"))
    }
}

// MARK: - Fixtures

private func makeSettings(enabled: Bool = true, consent: Bool = true, key: String? = "test-key", courses: Set<String> = ["1"]) -> CloudSettings {
    let settings = CloudSettings(defaults: UserDefaults(suiteName: "cloud-tests-\(UUID())")!, keyStore: .inMemory(key))
    settings.isEnabled = enabled
    settings.consentAcceptedAt = consent ? .now : nil
    settings.optedInCourseIDs = courses
    return settings
}

/// Records every request and answers with queued responses.
private actor FakeGemini {
    private(set) var requests: [URLRequest] = []
    private var replies: [(Int, String)]

    init(_ replies: [(status: Int, body: String)]) {
        self.replies = replies.map { ($0.status, $0.body) }
    }

    func send(_ request: URLRequest) throws -> (Data, URLResponse) {
        requests.append(request)
        let (status, body) = replies.isEmpty ? (500, "{}") : replies.removeFirst()
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (Data(body.utf8), response)
    }

    func bodies() -> [GeminiAPI.Request] {
        requests.compactMap { $0.httpBody.flatMap { try? JSONDecoder().decode(GeminiAPI.Request.self, from: $0) } }
    }
}

private func egress(_ settings: CloudSettings, _ fake: FakeGemini, names: [String] = ["Jane Smith"]) -> CloudEgress {
    CloudEgress(
        settings: settings,
        makeRedactor: { EgressRedactor(names: names) },
        transport: { try await fake.send($0) }
    )
}

private func textReply(_ text: String) -> (status: Int, body: String) {
    let response = GeminiAPI.Response(candidates: [.init(content: .init(role: "model", parts: [.init(text: text)]), finishReason: "STOP")])
    return (200, String(decoding: try! JSONEncoder().encode(response), as: UTF8.self))
}

private func callReply(_ name: String, args: JSONValue = .object([:])) -> (status: Int, body: String) {
    let response = GeminiAPI.Response(candidates: [.init(content: .init(role: "model", parts: [.init(functionCall: .init(name: name, args: args))]), finishReason: "STOP")])
    return (200, String(decoding: try! JSONEncoder().encode(response), as: UTF8.self))
}

// MARK: - Egress

struct CloudEgressTests {
    @Test func refusesUntilEverythingIsSetUp() {
        let fake = FakeGemini([])
        #expect(throws: CloudEgressError.disabled) { try egress(makeSettings(enabled: false), fake).authorize(courseIDs: []) }
        #expect(throws: CloudEgressError.consentRequired) { try egress(makeSettings(consent: false), fake).authorize(courseIDs: []) }
        #expect(throws: CloudEgressError.missingAPIKey) { try egress(makeSettings(key: nil), fake).authorize(courseIDs: []) }
        #expect(throws: CloudEgressError.courseNotShared(["2"])) { try egress(makeSettings(), fake).authorize(courseIDs: ["1", "2"]) }
        #expect(throws: Never.self) { try egress(makeSettings(), fake).authorize(courseIDs: ["1"]) }
    }

    @Test func sendsNothingWhenRefused() async {
        let fake = FakeGemini([textReply("{}")])
        await #expect(throws: CloudEgressError.courseNotShared(["9"])) {
            try await egress(makeSettings(), fake).generateContent(.init(contents: [.user("hi")]), courseIDs: ["9"])
        }
        #expect(await fake.requests.isEmpty)
    }

    @Test func redactsAndPutsTheKeyInAHeader() async throws {
        let fake = FakeGemini([textReply("ok")])
        let response = try await egress(makeSettings(), fake).generateContent(
            .init(contents: [.user("Is Jane Smith (jane@gatech.edu) my TA?")]),
            courseIDs: ["1"]
        )

        #expect(response.text == "ok")
        let request = try #require(await fake.requests.first)
        #expect(request.value(forHTTPHeaderField: "x-goog-api-key") == "test-key")
        #expect(request.url?.absoluteString.contains("key=") == false)
        #expect(request.url?.lastPathComponent == "\(CloudSettings.defaultModel):generateContent")
        #expect(await fake.bodies().first?.contents.first?.parts.first?.text == "Is [person] ([email]) my TA?")
    }

    @Test func mapsHTTPErrors() async {
        let fake = FakeGemini([(429, #"{"error":{"code":429,"message":"Quota exceeded"}}"#)])
        await #expect(throws: CloudEgressError.http(status: 429, message: "Quota exceeded")) {
            try await egress(makeSettings(), fake).generateContent(.init(contents: [.user("hi")]), courseIDs: [])
        }
        #expect(CloudEgressError.http(status: 429, message: nil).agentError == .rateLimited)
        #expect(CloudEgressError.missingAPIKey.agentError == .unavailable(CloudEgressError.missingAPIKey.errorDescription!))
    }
}

// MARK: - Provider

@available(iOS 26.0, macOS 26.0, *)
@Generable
struct CloudTestAnswer {
    var summary: String
    var citedIDs: [String]
}

@MainActor
private final class TwoCourseDataSource: AgentDataSource {
    func courses() async throws -> [Evidence] {
        [
            Evidence(ref: .course(id: "1"), title: "CS 1331", snippet: nil),
            Evidence(ref: .course(id: "2"), title: "PSYC 1101", snippet: nil),
        ]
    }
    func assignments(courseID: String) async throws -> [Evidence] { [] }
    func announcements(courseID: String) async throws -> [Evidence] { [] }
    func calendarEvents(courseID: String) async throws -> [Evidence] { [] }
    func toDos() async throws -> [Evidence] { [] }
    func files(courseID: String) async throws -> [Evidence] { [] }
}

@MainActor
struct GeminiProviderTests {
    @Test func answersWithoutToolsInOneCall() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let fake = FakeGemini([textReply(#"{"summary":"Nothing due.","citedIDs":[]}"#)])
        let provider = GeminiProvider(egress: egress(makeSettings(), fake))

        let response = try await provider.respond(
            to: AgentPrompt(instructions: "Be brief.", text: "What's due?", courseIDs: ["1"]),
            tools: [],
            generating: CloudTestAnswer.self
        )

        #expect(response.content.summary == "Nothing due.")
        #expect(response.tier == .cloud)
        let body = try #require(await fake.bodies().first)
        #expect(body.generationConfig?.responseMimeType == "application/json")
        #expect(body.generationConfig?.responseJsonSchema != nil)
        #expect(body.tools == nil)
    }

    @Test func runsToolsThenAsksForTheSchema() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let fake = FakeGemini([
            callReply("listCourses"),
            textReply("I have what I need."),
            textReply(#"{"summary":"You take CS 1331.","citedIDs":["course:1"]}"#),
        ])
        let provider = GeminiProvider(egress: egress(makeSettings(courses: ["1"]), fake))

        let response = try await provider.respond(
            to: AgentPrompt(instructions: "Answer.", text: "Which courses?"),
            tools: [ListCoursesTool(dataSource: TwoCourseDataSource())],
            generating: CloudTestAnswer.self
        )

        #expect(response.toolCalls == ["listCourses"])
        #expect(response.content.citedIDs == ["course:1"])

        let bodies = await fake.bodies()
        #expect(bodies.count == 3)
        #expect(bodies[0].tools?.first?.functionDeclarations.map(\.name) == ["listCourses"])
        #expect(bodies[0].tools?.first?.functionDeclarations.first?.parametersJsonSchema != nil)
        #expect(bodies[2].tools == nil)

        // The course that isn't shared never reaches the request.
        let toolResult = bodies[1].contents.flatMap(\.parts).compactMap(\.functionResponse).first?.response.jsonString ?? ""
        #expect(toolResult.contains("CS 1331"))
        #expect(!toolResult.contains("PSYC"))
        #expect(toolResult.contains("1 more from courses not shared"))
    }

    @Test func unknownToolsAndToolErrorsGoBackToTheModel() async throws {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let fake = FakeGemini([
            callReply("deleteEverything"),
            textReply("ok"),
            textReply(#"{"summary":"Done.","citedIDs":[]}"#),
        ])
        let provider = GeminiProvider(egress: egress(makeSettings(), fake))

        _ = try await provider.respond(
            to: AgentPrompt(instructions: "", text: "Hi"),
            tools: [ListCoursesTool(dataSource: TwoCourseDataSource())],
            generating: CloudTestAnswer.self
        )

        let error = await fake.bodies()[1].contents.flatMap(\.parts).compactMap(\.functionResponse).first?.response
        #expect(error == .object(["error": .string("No tool named deleteEverything.")]))
    }

    @Test func refusesBeforeSendingWhenNotSetUp() async {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let fake = FakeGemini([])
        let provider = GeminiProvider(egress: egress(makeSettings(key: nil), fake))
        #expect(!provider.isAvailable)

        await #expect(throws: AgentModelError.self) {
            _ = try await provider.respond(to: AgentPrompt(instructions: "", text: "Hi"), tools: [], generating: CloudTestAnswer.self)
        }
        #expect(await fake.requests.isEmpty)
    }

    @Test func blockedRepliesAreGuardrailViolations() async {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let blocked = (200, #"{"promptFeedback":{"blockReason":"SAFETY"}}"#)
        let provider = GeminiProvider(egress: egress(makeSettings(), FakeGemini([blocked])))

        await #expect(throws: AgentModelError.guardrailViolation) {
            _ = try await provider.respond(to: AgentPrompt(instructions: "", text: "Hi"), tools: [], generating: CloudTestAnswer.self)
        }
    }
}

// MARK: - Routing and spend

struct CloudRoutingTests {
    @Test func usesCloudOnlyWhenTheTaskAllowsIt() {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let ready = GeminiProvider(egress: CloudEgress(settings: makeSettings()))
        let router = AgentModelRouter(onDevice: NoModelProvider.unavailable, cloud: ready)

        #expect(router.provider().tier == .none)
        #expect(router.provider(allowing: [.onDevice]).tier == .none)
        #expect(router.provider(allowing: [.cloud]).tier == .cloud)
        #expect(router.provider(allowing: [.onDevice, .cloud]).tier == .cloud)
    }

    @Test func fallsBackToNoModelWhenCloudIsntSetUp() {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let notReady = GeminiProvider(egress: CloudEgress(settings: makeSettings(enabled: false)))
        let router = AgentModelRouter(onDevice: NoModelProvider.unavailable, cloud: notReady)
        #expect(router.provider(allowing: [.cloud]).tier == .none)
    }

    @Test func sumsCloudModelCallsFromTheLedger() {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        func call(_ tier: AgentTier, _ prompt: Int, _ output: Int) -> LedgerEntry {
            LedgerEntry(
                id: UUID(), runID: UUID(), sequence: 0, timestamp: .now,
                kind: .modelCall(tier: "\(tier)", provider: "P", promptTokens: prompt, outputTokens: output, toolCalls: [], error: nil),
                duration: nil, usage: nil
            )
        }

        let usage = CloudUsage(entries: [call(.cloud, 1_000_000, 0), call(.onDevice, 500, 500), call(.cloud, 0, 1_000_000)])
        #expect(usage.calls == 2)
        #expect(usage.promptTokens == 1_000_000)
        #expect(abs(usage.estimatedCost - (CloudUsage.inputPricePerMillion + CloudUsage.outputPricePerMillion)) < 1e-9)
    }
}

@available(iOS 26.0, macOS 26.0, *)
private extension NoModelProvider {
    /// A provider that reports itself unavailable, standing in for an on-device model that can't run.
    static var unavailable: some AgentModelProvider { UnavailableProvider() }
}

@available(iOS 26.0, macOS 26.0, *)
private struct UnavailableProvider: AgentModelProvider {
    let tier = AgentTier.onDevice
    let isAvailable = false

    func respond<Output: Generable>(to prompt: AgentPrompt, tools: [any Tool], generating type: Output.Type) async throws -> AgentResponse<Output> {
        throw AgentModelError.unavailable("test")
    }
}

struct GeminiSchemaTests {
    @Test func inlinesDefinitionsAndDropsTitles() {
        guard #available(iOS 26.0, macOS 26.0, *) else { return }
        let schema: JSONValue = .object([
            "title": .string("Answer"),
            "type": .string("object"),
            "$defs": .object(["Sentence": .object(["title": .string("Sentence"), "type": .string("object"), "properties": .object(["text": .object(["type": .string("string")])])])]),
            "properties": .object(["sentences": .object(["type": .string("array"), "items": .object(["$ref": .string("#/$defs/Sentence")])])]),
        ])

        let flat = GeminiProvider.inliningReferences(schema).jsonString
        #expect(!flat.contains("$defs"))
        #expect(!flat.contains("$ref"))
        #expect(!flat.contains("title"))
        #expect(flat.contains(#""items":{"properties":{"text":{"type":"string"}},"type":"object"}"#))
    }

    @Test func errorsReadAsSentences() {
        #expect(AgentModelError.other("Gemini returned an error (400).").localizedDescription == "Gemini returned an error (400).")
        #expect(AgentModelError.rateLimited.localizedDescription.hasPrefix("Too many requests"))
    }
}
