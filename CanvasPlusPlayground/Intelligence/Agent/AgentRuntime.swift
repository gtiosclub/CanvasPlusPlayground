//
//  AgentRuntime.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/24/26.
//

import Foundation
import FoundationModels

// MARK: - State

/// A typed key into `AgentRunState`, e.g. `static let assignments = AgentStateKey<[Evidence]>("assignments")`.
struct AgentStateKey<Value: Codable & Sendable>: Sendable {
    let name: String

    init(_ name: String) {
        self.name = name
    }
}

/// What a run's nodes hand to each other. Values are stored encoded, so the whole state can be
/// written to a checkpoint after every node and read back when the run resumes.
struct AgentRunState: Codable, Hashable, Sendable {
    private var values: [String: Data] = [:]

    init() {}

    subscript<Value>(key: AgentStateKey<Value>) -> Value? {
        guard let data = values[key.name] else { return nil }
        return try? JSONDecoder().decode(Value.self, from: data)
    }

    mutating func set<Value>(_ value: Value?, for key: AgentStateKey<Value>) throws {
        values[key.name] = try value.map { try JSONEncoder().encode($0) }
    }

    var keys: [String] {
        values.keys.sorted()
    }
}

// MARK: - Graph

enum AgentTransition: Hashable, Sendable {
    /// Run the node with this id next.
    case next(String)
    case finish
}

/// One step of an agent (plan, gather, reconcile, gate, emit…). Nodes should check
/// `Task.isCancelled` during long work; the runtime cancels them when the run's time is up.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
protocol AgentNode: Sendable {
    nonisolated var id: String { get }

    func run(in context: AgentNodeContext) async throws -> AgentTransition
}

/// A node made from a closure, for small steps that don't need their own type.
@available(iOS 26.0, macOS 26.0, *)
struct AgentStep: AgentNode {
    let id: String
    let body: @MainActor @Sendable (AgentNodeContext) async throws -> AgentTransition

    init(_ id: String, body: @escaping @MainActor @Sendable (AgentNodeContext) async throws -> AgentTransition) {
        self.id = id
        self.body = body
    }

    func run(in context: AgentNodeContext) async throws -> AgentTransition {
        try await body(context)
    }
}

/// The nodes of one kind of run and where it starts. `name` is saved with checkpoints so a
/// run can only be resumed by the graph that started it, so keep it stable.
@available(iOS 26.0, macOS 26.0, *)
struct AgentGraph {
    let name: String
    let startNodeID: String
    private let nodes: [String: any AgentNode]

    init(name: String, start: String, nodes: [any AgentNode]) {
        self.name = name
        self.startNodeID = start
        self.nodes = Dictionary(nodes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    func node(_ id: String) throws -> any AgentNode {
        guard let node = nodes[id] else { throw AgentRunError.unknownNode(id) }
        return node
    }
}

// MARK: - Context

/// What a node gets while it runs: the shared state, the model, and the budget.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
final class AgentNodeContext {
    let runID: UUID
    let budget: AgentBudget
    let provider: any AgentModelProvider
    let estimator: TokenEstimator
    let ledger: ExecutionLedger?
    var state: AgentRunState
    private(set) var usage: AgentUsage

    init(
        runID: UUID,
        budget: AgentBudget,
        provider: any AgentModelProvider,
        estimator: TokenEstimator,
        ledger: ExecutionLedger?,
        state: AgentRunState,
        usage: AgentUsage
    ) {
        self.runID = runID
        self.budget = budget
        self.provider = provider
        self.estimator = estimator
        self.ledger = ledger
        self.state = state
        self.usage = usage
    }

    /// Records a decision in the run's ledger, e.g. "Kept 4 records, summarized 2".
    func note(_ decision: String) {
        ledger?.record(.decision(decision), runID: runID)
    }

    /// Tokens left in the run's budget.
    var remainingTokens: Int {
        max(budget.maxTokens - usage.tokens, 0)
    }

    /// The most prompt tokens the next call can use: whatever is smaller of the context window
    /// (minus the output reserve) and what's left of the run's budget.
    var promptTokenAllowance: Int {
        min(budget.maxPromptTokens, max(remainingTokens - budget.outputReserve, 0))
    }

    /// Calls the model, charging the estimated tokens to the run.
    ///
    /// Fails fast, without calling the model, when the prompt wouldn't fit in the context window
    /// or the run doesn't have the tokens left. Tool output added during the call isn't counted,
    /// which is why the window keeps `outputReserve` free.
    func respond<Output: Generable>(
        to prompt: AgentPrompt,
        tools: [any Tool] = [],
        generating type: Output.Type
    ) async throws -> AgentResponse<Output> {
        let promptTokens = estimatedTokens(for: prompt, tools: tools)

        guard promptTokens <= budget.maxPromptTokens else {
            throw AgentModelError.contextWindowExceeded
        }
        guard usage.tokens + promptTokens <= budget.maxTokens else {
            throw AgentRunError.tokenBudgetExceeded(limit: budget.maxTokens)
        }

        usage.modelCalls += 1
        usage.tokens += promptTokens

        let tools = ledger?.recording(tools, runID: runID) ?? tools
        let clock = ContinuousClock()
        let started = clock.now

        do {
            let response = try await provider.respond(to: prompt, tools: tools, generating: type)
            let outputTokens = estimator.tokens(in: response.content.generatedContent.jsonString)
            usage.tokens += outputTokens

            ledger?.record(
                .modelCall(
                    tier: "\(response.tier)",
                    provider: String(describing: Swift.type(of: provider)),
                    promptTokens: promptTokens,
                    outputTokens: outputTokens,
                    toolCalls: response.toolCalls,
                    error: nil
                ),
                runID: runID,
                duration: clock.now - started
            )
            return response
        } catch {
            ledger?.record(
                .modelCall(
                    tier: "\(provider.tier)",
                    provider: String(describing: Swift.type(of: provider)),
                    promptTokens: promptTokens,
                    outputTokens: 0,
                    toolCalls: [],
                    error: error.localizedDescription
                ),
                runID: runID,
                duration: clock.now - started
            )
            throw error
        }
    }

    func estimatedTokens(for prompt: AgentPrompt, tools: [any Tool]) -> Int {
        let toolText = tools.map { "\($0.name) \($0.description)" }.joined(separator: "\n")
        return estimator.tokens(in: prompt.instructions)
            + estimator.tokens(in: prompt.text)
            + estimator.tokens(in: toolText)
    }

    func value<Value>(_ key: AgentStateKey<Value>) -> Value? {
        state[key]
    }

    func set<Value>(_ value: Value?, for key: AgentStateKey<Value>) throws {
        try state.set(value, for: key)
    }

    fileprivate func addStep() {
        usage.steps += 1
    }

    fileprivate func addElapsed(_ duration: Duration) {
        usage.elapsed += duration
    }
}

// MARK: - Runtime

struct AgentRunResult: Sendable {
    let runID: UUID
    let status: AgentRunStatus
    let state: AgentRunState
    let usage: AgentUsage
}

/// Runs an `AgentGraph` one node at a time inside an `AgentBudget`.
///
/// - Budgets: steps and tokens are checked before each node and each model call. Time is enforced
///   while a node runs: when it's up the node's task is cancelled.
/// - Cancellation: cancelling the task that called `start` or `resume` stops the run between
///   nodes (or inside a node that checks for it) and saves it as `.paused`.
/// - Checkpoints: the state is saved after every node, so a run interrupted by the app being
///   suspended or killed resumes from the next node instead of starting over.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
final class AgentRuntime {
    private let store: AgentRunStore?
    private let provider: any AgentModelProvider
    private let budget: AgentBudget
    private let estimator: TokenEstimator
    private let ledger: ExecutionLedger?
    private let clock = ContinuousClock()

    /// - Parameters:
    ///   - store: where checkpoints go. `nil` runs without saving (nothing to resume).
    ///   - ledger: where the trace goes. `nil` records nothing.
    init(
        provider: any AgentModelProvider,
        budget: AgentBudget = .onDevice,
        store: AgentRunStore?,
        ledger: ExecutionLedger? = nil,
        estimator: TokenEstimator = TokenEstimator()
    ) {
        self.provider = provider
        self.budget = budget
        self.store = store
        self.ledger = ledger
        self.estimator = estimator
    }

    /// Saves checkpoints and the trace to the app's shared store.
    convenience init(provider: any AgentModelProvider, budget: AgentBudget = .onDevice) {
        self.init(provider: provider, budget: budget, store: .shared, ledger: .shared)
    }

    /// Starts a new run of `graph` with `state` as its input.
    @discardableResult
    func start(_ graph: AgentGraph, state: AgentRunState = AgentRunState()) async throws -> AgentRunResult {
        let snapshot = AgentRunSnapshot(
            runID: UUID(),
            graphName: graph.name,
            nextNodeID: graph.startNodeID,
            state: state,
            usage: AgentUsage(),
            budget: budget,
            status: .running,
            errorMessage: nil,
            startedAt: .now,
            updatedAt: .now
        )
        try store?.save(snapshot)
        ledger?.record(.runStarted(graph: graph.name), runID: snapshot.runID)

        return try await execute(graph, from: snapshot)
    }

    /// Continues a saved run from the node after its last checkpoint, with the budget it started with.
    @discardableResult
    func resume(_ graph: AgentGraph, runID: UUID) async throws -> AgentRunResult {
        guard let snapshot = try store?.snapshot(for: runID) else {
            throw AgentRunError.checkpointNotFound(runID)
        }
        guard snapshot.graphName == graph.name else {
            throw AgentRunError.graphMismatch(expected: graph.name, found: snapshot.graphName)
        }
        guard snapshot.status.isResumable else {
            throw AgentRunError.notResumable(snapshot.status)
        }

        var resumed = snapshot
        resumed.status = .running
        resumed.errorMessage = nil
        ledger?.record(
            .runResumed(graph: graph.name, atNode: snapshot.nextNodeID ?? graph.startNodeID),
            runID: snapshot.runID,
            usage: snapshot.usage
        )
        return try await execute(graph, from: resumed)
    }

    /// Resumes the newest unfinished run of `graph`, or starts a new one with `state`.
    @discardableResult
    func resumeOrStart(_ graph: AgentGraph, state: AgentRunState = AgentRunState()) async throws -> AgentRunResult {
        if let unfinished = try store?.latestResumable(graphName: graph.name) {
            return try await resume(graph, runID: unfinished.runID)
        }

        return try await start(graph, state: state)
    }

    /// Marks a saved run as discarded so `resumeOrStart` won't pick it up.
    func discard(runID: UUID) throws {
        guard var snapshot = try store?.snapshot(for: runID) else { return }
        snapshot.status = .cancelled
        snapshot.nextNodeID = nil
        snapshot.updatedAt = .now
        try store?.save(snapshot)
    }

    // MARK: Loop

    private func execute(_ graph: AgentGraph, from snapshot: AgentRunSnapshot) async throws -> AgentRunResult {
        var snapshot = snapshot
        let budget = snapshot.budget
        let context = AgentNodeContext(
            runID: snapshot.runID,
            budget: budget,
            provider: provider,
            estimator: estimator,
            ledger: ledger,
            state: snapshot.state,
            usage: snapshot.usage
        )

        do {
            while let nodeID = snapshot.nextNodeID {
                try Task.checkCancellation()
                try checkBudget(context.usage, against: budget)

                let node = try graph.node(nodeID)
                context.addStep()

                let started = clock.now
                let transition: AgentTransition
                do {
                    transition = try await runWithTimeLimit(
                        node,
                        in: context,
                        timeLeft: budget.maxDuration - context.usage.elapsed
                    )
                } catch {
                    context.addElapsed(clock.now - started)
                    throw error
                }
                context.addElapsed(clock.now - started)

                switch transition {
                case .next(let id):
                    snapshot.nextNodeID = id
                case .finish:
                    snapshot.nextNodeID = nil
                    snapshot.status = .finished
                }

                ledger?.record(
                    .node(id: nodeID, transition: snapshot.nextNodeID),
                    runID: snapshot.runID,
                    duration: clock.now - started,
                    usage: context.usage
                )

                snapshot.state = context.state
                snapshot.usage = context.usage
                snapshot.updatedAt = .now
                try store?.save(snapshot)
            }
        } catch {
            snapshot.state = context.state
            snapshot.usage = context.usage
            snapshot.updatedAt = .now

            if error is CancellationError {
                // Keep `nextNodeID` so the run picks up at the node that was interrupted.
                snapshot.status = .paused
            } else {
                snapshot.status = .failed
                snapshot.nextNodeID = nil
                snapshot.errorMessage = error.localizedDescription
            }

            try? store?.save(snapshot)
            ledger?.record(
                .runEnded(status: snapshot.status, message: snapshot.status == .paused ? nil : error.localizedDescription),
                runID: snapshot.runID,
                usage: snapshot.usage
            )
            throw error
        }

        ledger?.record(.runEnded(status: snapshot.status, message: nil), runID: snapshot.runID, usage: snapshot.usage)

        return AgentRunResult(
            runID: snapshot.runID,
            status: snapshot.status,
            state: snapshot.state,
            usage: snapshot.usage
        )
    }

    private func checkBudget(_ usage: AgentUsage, against budget: AgentBudget) throws {
        if usage.steps >= budget.maxSteps {
            throw AgentRunError.stepBudgetExceeded(limit: budget.maxSteps)
        }
        if usage.elapsed >= budget.maxDuration {
            throw AgentRunError.timeBudgetExceeded(limit: budget.maxDuration)
        }
        if usage.tokens >= budget.maxTokens {
            throw AgentRunError.tokenBudgetExceeded(limit: budget.maxTokens)
        }
    }

    /// Runs `node`, cancelling it if it's still going when `timeLeft` runs out.
    private func runWithTimeLimit(
        _ node: any AgentNode,
        in context: AgentNodeContext,
        timeLeft: Duration
    ) async throws -> AgentTransition {
        let limit = context.budget.maxDuration

        return try await withThrowingTaskGroup(of: AgentTransition?.self) { group in
            group.addTask { @MainActor in
                try await node.run(in: context)
            }
            group.addTask {
                try await Task.sleep(for: timeLeft)
                return nil
            }

            defer { group.cancelAll() }

            guard let first = try await group.next() else {
                throw CancellationError()
            }
            guard let transition = first else {
                throw AgentRunError.timeBudgetExceeded(limit: limit)
            }

            return transition
        }
    }
}
