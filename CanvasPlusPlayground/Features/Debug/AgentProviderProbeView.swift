//
//  AgentProviderProbeView.swift
//  CanvasPlusPlayground
//
//  TEMPORARY: manual on-device checks for PR #658 (AgentModelProvider). Do not commit.
//

#if DEBUG
import FoundationModels
import SwiftUI

// MARK: - Output types used by the probes

@available(iOS 26.0, macOS 26.0, *)
@Generable
struct AgentProbeEcho {
    @Guide(description: "The exact word the user asked you to repeat, or \"unknown\" if you don't know it.")
    var word: String

    @Guide(description: "Any whole number from 1 to 10.", .range(1...10))
    var number: Int
}

@available(iOS 26.0, macOS 26.0, *)
@Generable
struct AgentProbeAnswer {
    @Guide(description: "One entry per fact you tell the student.")
    var claims: [AgentProbeClaim]
}

@available(iOS 26.0, macOS 26.0, *)
@Generable
struct AgentProbeClaim {
    @Guide(description: "One short sentence for the student.")
    var text: String

    @Guide(description: "The ids in square brackets from the tool results that support this sentence, like assignment:1234.")
    var evidenceIDs: [String]

    @Guide(description: "If the sentence mentions a due date, copy the due value from the tool result exactly. Otherwise leave this empty.")
    var dueDate: String?
}

// MARK: - Data source that records what the tools saw

/// Wraps the real data source, remembers every Evidence it hands to a tool,
/// and can be told to fail so we can see how tool errors surface.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
final class RecordingAgentDataSource: AgentDataSource {
    struct ProbeFailure: LocalizedError {
        var errorDescription: String? { "Probe: forced data source failure" }
    }

    private let base: any AgentDataSource
    private(set) var seen: [String: Evidence] = [:]
    var failEverything = false

    init(base: any AgentDataSource) {
        self.base = base
    }

    func reset() {
        seen = [:]
        failEverything = false
    }

    private func record(_ load: () async throws -> [Evidence]) async throws -> [Evidence] {
        if failEverything { throw ProbeFailure() }
        let items = try await load()
        for item in items { seen[item.id] = item }
        return items
    }

    func courses() async throws -> [Evidence] { try await record { try await base.courses() } }
    func assignments(courseID: String) async throws -> [Evidence] { try await record { try await base.assignments(courseID: courseID) } }
    func announcements(courseID: String) async throws -> [Evidence] { try await record { try await base.announcements(courseID: courseID) } }
    func calendarEvents(courseID: String) async throws -> [Evidence] { try await record { try await base.calendarEvents(courseID: courseID) } }
    func toDos() async throws -> [Evidence] { try await record { try await base.toDos() } }
    func files(courseID: String) async throws -> [Evidence] { try await record { try await base.files(courseID: courseID) } }
}

// MARK: - Probe screen

@available(iOS 26.0, macOS 26.0, *)
struct AgentProviderProbeView: View {
    let courseManager: CourseManager

    @State private var log: [String] = []
    @State private var isRunning = false
    @State private var dataSource: RecordingAgentDataSource?

    private let provider = OnDeviceModelProvider()

    private let instructions = """
    You help a college student with their Canvas courses. Use the tools to look things up. \
    Only state facts that appear in tool results, and cite the id in square brackets for every fact.
    """

    var body: some View {
        List {
            Section("Run") {
                Button("0 · Availability and router") { run("0 Availability", probeAvailability) }
                Button("1 · Typed output, no tools") { run("1 Typed output", probeTypedOutput) }
                Button("2 · Fresh session per call") { run("2 Fresh session", probeFreshSession) }
                Button("3 · Tools + nested claims") { run("3 Tools + claims", probeToolsAndClaims) }
                Button("3× · Repeat probe 3 five times") { run("3x Repeat", probeRepeat) }
                Button("4 · Course by name") { run("4 Course by name", probeCourseByName) }
                Button("5 · Context window overflow") { run("5 Context overflow", probeContextOverflow) }
                Button("6 · Tool failure error type") { run("6 Tool failure", probeToolFailure) }
                Button("Clear log", role: .destructive) { log.removeAll() }
            }
            .disabled(isRunning)

            Section("Log") {
                if isRunning { ProgressView() }
                ForEach(Array(log.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Agent Provider Probe")
        .toolbar {
            ShareLink(item: log.joined(separator: "\n"))
        }
    }

    // MARK: Runner

    private func run(_ name: String, _ probe: @escaping () async throws -> Void) {
        isRunning = true
        Task { @MainActor in
            log.append("──── \(name) ────")
            let start = Date.now
            do {
                try await probe()
            } catch {
                log.append("THREW \(String(reflecting: type(of: error))): \(error)")
            }
            log.append(String(format: "(%.1fs)", Date.now.timeIntervalSince(start)))
            isRunning = false
        }
    }

    private func say(_ line: String) { log.append(line) }
    private func check(_ ok: Bool, _ label: String) { log.append("\(ok ? "PASS" : "FAIL") \(label)") }

    private func makeDataSource() -> RecordingAgentDataSource {
        let source = dataSource ?? RecordingAgentDataSource(
            base: CanvasCacheAgentDataSource(courseManager: courseManager, toDoListManager: ToDoListManager())
        )
        source.reset()
        dataSource = source
        return source
    }

    // MARK: Probes

    private func probeAvailability() async throws {
        say("isSandbox = \(AppEnvironment.isSandbox)")
        say("availability = \(SystemLanguageModel.default.availability)")
        say("description = \(IntelligenceSupport.modelAvailabilityDescription)")
        check(provider.isAvailable, "OnDeviceModelProvider.isAvailable")

        let router = AgentModelRouter()
        check(router.provider(allowing: [.onDevice]).tier == .onDevice, "router picks .onDevice when allowed")
        check(router.provider(allowing: []).tier == AgentTier.none, "router picks .none when nothing allowed")
        check(router.provider(allowing: [.cloud]).tier == AgentTier.none, "router ignores .cloud for now")
    }

    private func probeTypedOutput() async throws {
        let response = try await provider.respond(
            to: AgentPrompt(instructions: "Answer exactly as asked.", text: "Repeat the word pineapple and pick a number."),
            tools: [],
            generating: AgentProbeEcho.self
        )
        say("content = \(response.content)")
        check(response.content.word.lowercased().contains("pineapple"), "word is pineapple")
        check((1...10).contains(response.content.number), "number within @Guide range 1...10")
        check(response.tier == .onDevice, "tier reported as .onDevice")
        check(response.toolCalls.isEmpty, "no tool calls")
    }

    private func probeFreshSession() async throws {
        let first = try await provider.respond(
            to: AgentPrompt(instructions: "Answer exactly as asked.", text: "Remember this secret word: zephyr. Repeat it back."),
            tools: [],
            generating: AgentProbeEcho.self
        )
        say("call 1 word = \(first.content.word)")

        let second = try await provider.respond(
            to: AgentPrompt(
                instructions: "Answer exactly as asked.",
                text: "What secret word did I tell you earlier in this conversation? If you don't know, answer unknown."
            ),
            tools: [],
            generating: AgentProbeEcho.self
        )
        say("call 2 word = \(second.content.word)")
        check(!second.content.word.lowercased().contains("zephyr"), "second call does not remember the first")
    }

    private func probeToolsAndClaims() async throws {
        try await toolsAndClaims(text: "What assignments do I have due in the next 14 days? Look them up with the tools.")
    }

    private func probeRepeat() async throws {
        for index in 1...5 {
            say("· run \(index)")
            do {
                try await toolsAndClaims(text: "What assignments do I have due in the next 14 days? Look them up with the tools.")
            } catch {
                say("run \(index) THREW \(String(reflecting: type(of: error))): \(error)")
            }
        }
    }

    private func probeCourseByName() async throws {
        let source = makeDataSource()
        guard let course = try await source.courses().first else {
            say("No courses loaded. Open a course list first (or use sandbox mode).")
            return
        }
        say("asking about course title = \(course.title)")
        try await toolsAndClaims(text: "What assignments are coming up in \(course.title)? Look them up with the tools.")
    }

    private func toolsAndClaims(text: String) async throws {
        let source = makeDataSource()
        let tools: [any Tool] = [
            ListCoursesTool(dataSource: source),
            ListAssignmentsTool(dataSource: source)
        ]

        let response = try await provider.respond(
            to: AgentPrompt(instructions: instructions, text: text, temperature: 0),
            tools: tools,
            generating: AgentProbeAnswer.self
        )

        say("toolCalls = \(response.toolCalls)")
        check(!response.toolCalls.isEmpty, "model called at least one tool")
        check(Set(response.toolCalls).isSubset(of: ["listCourses", "listAssignments"]), "tool names come from the transcript correctly")
        say("evidence the tools returned: \(source.seen.count) records")
        check(!response.content.claims.isEmpty, "answer has at least one claim")

        let iso = ISO8601DateFormatter()
        for (index, claim) in response.content.claims.enumerated() {
            say("claim \(index + 1): \(claim.text)")
            say("   ids = \(claim.evidenceIDs)  dueDate = \(claim.dueDate ?? "nil")")

            let unknown = claim.evidenceIDs.filter { source.seen[$0] == nil }
            check(!claim.evidenceIDs.isEmpty, "   cites something")
            check(unknown.isEmpty, "   every cited id was returned by a tool \(unknown.isEmpty ? "" : "(made up: \(unknown))")")

            if let dueText = claim.dueDate, !dueText.isEmpty {
                guard let claimed = iso.date(from: dueText) else {
                    check(false, "   dueDate parses as ISO 8601")
                    continue
                }
                let sourceDates = claim.evidenceIDs.compactMap { source.seen[$0]?.facts.dueDate }
                let matching = sourceDates.contains { abs($0.timeIntervalSince(claimed)) < 60 }
                check(matching, "   dueDate matches a cited record (source: \(sourceDates.map { iso.string(from: $0) }))")
            }
            say("   ↳ compare by eye: does the sentence say the same date as dueDate?")
        }
    }

    private func probeContextOverflow() async throws {
        let filler = String(repeating: "The quick brown fox jumps over the lazy dog. ", count: 2_000)
        do {
            _ = try await provider.respond(
                to: AgentPrompt(instructions: "Answer exactly as asked.", text: filler + "Repeat the word pineapple."),
                tools: [],
                generating: AgentProbeEcho.self
            )
            check(false, "expected AgentModelError.contextWindowExceeded, but the call succeeded")
        } catch let error as AgentModelError {
            say("error = \(error)")
            check(error == .contextWindowExceeded, "mapped to AgentModelError.contextWindowExceeded")
        }
    }

    private func probeToolFailure() async throws {
        let source = makeDataSource()
        source.failEverything = true
        defer { source.failEverything = false }

        do {
            _ = try await provider.respond(
                to: AgentPrompt(instructions: instructions, text: "What assignments do I have due this week? Look them up with the tools."),
                tools: [ListCoursesTool(dataSource: source), ListAssignmentsTool(dataSource: source)],
                generating: AgentProbeAnswer.self
            )
            say("The call succeeded even though every tool call failed. The model may have answered without tools.")
        } catch let error as AgentModelError {
            say("error = \(error)")
            check(true, "tool failure surfaced as AgentModelError")
        } catch {
            say("error type = \(String(reflecting: type(of: error)))")
            say("error = \(error)")
            check(false, "tool failure surfaced as AgentModelError (it escaped unmapped)")
        }
    }
}
#endif
