//
//  ExecutionLedger.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/24/26.
//

import Foundation
import FoundationModels

/// One thing that happened during a run.
struct LedgerEntry: Identifiable, Codable, Hashable, Sendable {
    enum Kind: Codable, Hashable, Sendable {
        case runStarted(graph: String)
        case runResumed(graph: String, atNode: String)
        /// A node finished. `transition` is the next node's id, or nil when the run finished.
        case node(id: String, transition: String?)
        /// `provider` is the type that answered (e.g. `ScriptedModelProvider` standing in for the
        /// on-device model). `error` is nil when the call succeeded.
        case modelCall(tier: String, provider: String, promptTokens: Int, outputTokens: Int, toolCalls: [String], error: String?)
        /// `recordIDs` are the evidence ids the tool returned, when it returns evidence.
        case toolCall(name: String, resultCount: Int?, recordIDs: [String], error: String?)
        /// Something a node decided, in plain words ("Kept 4 records, summarized 2").
        case decision(String)
        case runEnded(status: AgentRunStatus, message: String?)
    }

    let id: UUID
    let runID: UUID
    /// Order within the run, starting at 0. Keeps counting across a resume.
    let sequence: Int
    let timestamp: Date
    let kind: Kind
    /// How long it took, for nodes, model calls and tool calls.
    let duration: Duration?
    /// The run's usage right after this entry. Set on node entries.
    let usage: AgentUsage?
}

/// Records every model call, tool call and decision in a run, with timings.
///
/// Entries are kept in memory for the run in progress (so a screen can watch it live) and
/// written to `AgentRunStore`, so the trace screen and, later, the "show your work" drawer can
/// read any past run.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
@Observable
final class ExecutionLedger {
    static let shared = ExecutionLedger(store: .shared)

    /// Entries recorded by this ledger since it was created, oldest first.
    private(set) var liveEntries: [LedgerEntry] = []

    @ObservationIgnored private let store: AgentRunStore?
    @ObservationIgnored private var nextSequence: [UUID: Int] = [:]

    /// - Parameter store: `nil` keeps entries in memory only.
    init(store: AgentRunStore?) {
        self.store = store
    }

    func record(
        _ kind: LedgerEntry.Kind,
        runID: UUID,
        duration: Duration? = nil,
        usage: AgentUsage? = nil
    ) {
        // After a resume (or a relaunch) keep numbering from what's already saved for the run.
        let sequence = nextSequence[runID] ?? (try? store?.ledgerEntryCount(runID: runID)) ?? 0
        nextSequence[runID] = sequence + 1

        let entry = LedgerEntry(
            id: UUID(),
            runID: runID,
            sequence: sequence,
            timestamp: .now,
            kind: kind,
            duration: duration,
            usage: usage
        )
        liveEntries.append(entry)

        do {
            try store?.append(entry)
        } catch {
            LoggerService.main.error("[Agent] Couldn't save ledger entry: \(error)")
        }
    }

    /// Every entry for `runID`, from the store if there is one, otherwise from memory.
    func entries(for runID: UUID) -> [LedgerEntry] {
        if let store, let saved = try? store.ledgerEntries(runID: runID) {
            return saved
        }

        return liveEntries.filter { $0.runID == runID }
    }
}

// MARK: - Tool recording

/// Wraps a tool so each call lands in the ledger with its timing and the records it returned.
@available(iOS 26.0, macOS 26.0, *)
struct LedgerRecordingTool<Base: Tool>: Tool {
    typealias Arguments = Base.Arguments
    typealias Output = Base.Output

    let base: Base
    let ledger: ExecutionLedger
    let runID: UUID

    var name: String { base.name }
    var description: String { base.description }
    var parameters: GenerationSchema { base.parameters }
    var includesSchemaInInstructions: Bool { base.includesSchemaInInstructions }

    func call(arguments: Arguments) async throws -> Output {
        let clock = ContinuousClock()
        let started = clock.now

        do {
            let output = try await base.call(arguments: arguments)
            let evidence = (output as? EvidenceBundle)?.evidence
            await ledger.record(
                .toolCall(name: name, resultCount: evidence?.count, recordIDs: evidence?.map(\.id) ?? [], error: nil),
                runID: runID,
                duration: clock.now - started
            )
            return output
        } catch {
            await ledger.record(
                .toolCall(name: name, resultCount: nil, recordIDs: [], error: error.localizedDescription),
                runID: runID,
                duration: clock.now - started
            )
            throw error
        }
    }
}

@available(iOS 26.0, macOS 26.0, *)
extension ExecutionLedger {
    /// `tools`, each wrapped so its calls are recorded under `runID`.
    func recording(_ tools: [any Tool], runID: UUID) -> [any Tool] {
        tools.map { wrap($0, runID: runID) }
    }

    private func wrap<T: Tool>(_ tool: T, runID: UUID) -> any Tool {
        LedgerRecordingTool(base: tool, ledger: self, runID: runID)
    }
}

// MARK: - Display

extension LedgerEntry.Kind {
    var title: String {
        switch self {
        case .runStarted(let graph):
            "Started \(graph)"
        case let .runResumed(graph, node):
            "Resumed \(graph) at \(node)"
        case .node(let id, _):
            "Node \(id)"
        case let .modelCall(tier, _, _, _, _, error):
            error == nil ? "Model call (\(tier))" : "Model call failed (\(tier))"
        case let .toolCall(name, _, _, error):
            error == nil ? "Tool \(name)" : "Tool \(name) failed"
        case .decision:
            "Decision"
        case .runEnded(let status, _):
            "Run \(status.rawValue)"
        }
    }

    var detail: String? {
        switch self {
        case .runStarted, .runResumed:
            nil
        case .node(_, let transition):
            transition.map { "→ \($0)" } ?? "→ finish"
        case let .modelCall(_, provider, promptTokens, outputTokens, toolCalls, error):
            [
                "~\(promptTokens) in · ~\(outputTokens) out · \(provider)",
                toolCalls.isEmpty ? nil : "tools: \(toolCalls.joined(separator: ", "))",
                error
            ]
            .compactMap { $0 }
            .joined(separator: "\n")
        case let .toolCall(_, count, ids, error):
            if let error {
                error
            } else if let count {
                ([count == 1 ? "1 record" : "\(count) records"] + ids.prefix(4)).joined(separator: " · ")
                    + (ids.count > 4 ? " …" : "")
            } else {
                nil
            }
        case .decision(let text):
            text
        case .runEnded(_, let message):
            message
        }
    }

    var systemImage: String {
        switch self {
        case .runStarted:
            "play.circle"
        case .runResumed:
            "arrow.clockwise.circle"
        case .node:
            "circle.hexagongrid"
        case .modelCall:
            "sparkles"
        case .toolCall:
            "wrench.and.screwdriver"
        case .decision:
            "arrow.triangle.branch"
        case .runEnded(let status, _):
            status == .finished ? "checkmark.circle" : status.isResumable ? "pause.circle" : "xmark.octagon"
        }
    }

    var isFailure: Bool {
        switch self {
        case let .modelCall(_, _, _, _, _, error), let .toolCall(_, _, _, error):
            error != nil
        case .runEnded(let status, _):
            status == .failed
        default:
            false
        }
    }
}
