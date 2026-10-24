//
//  AgentRunStore.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/24/26.
//

import Foundation
import SwiftData

enum AgentRunStatus: String, Codable, Sendable, CaseIterable {
    /// In progress, or the app was killed mid-run. Resumable.
    case running
    /// The task running it was cancelled (e.g. the screen went away). Resumable.
    case paused
    case finished
    case failed
    /// Discarded on purpose. Not resumable.
    case cancelled

    var isResumable: Bool {
        self == .running || self == .paused
    }
}

/// Everything needed to pick a run back up: where it was, what it had, and what it had used.
struct AgentRunSnapshot: Identifiable, Hashable, Sendable {
    let runID: UUID
    let graphName: String
    /// The node to run next. `nil` once the run is over.
    var nextNodeID: String?
    var state: AgentRunState
    var usage: AgentUsage
    var budget: AgentBudget
    var status: AgentRunStatus
    var errorMessage: String?
    let startedAt: Date
    var updatedAt: Date

    var id: UUID { runID }
}

typealias AgentRunCheckpoint = AgentRunSchemaV1.AgentRunCheckpoint
typealias AgentLedgerRecord = AgentRunSchemaV1.AgentLedgerRecord

/// Agent state gets its own schema and store file so it never touches `CanvasSchema`
/// and can be deleted without losing the Canvas cache.
enum AgentRunSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [AgentRunCheckpoint.self, AgentLedgerRecord.self]
    }
}

extension AgentRunSchemaV1 {
    @Model
    final class AgentRunCheckpoint {
        @Attribute(.unique) var runID: UUID
        var graphName: String
        var nextNodeID: String?
        var stateData: Data
        var usageData: Data
        var budgetData: Data
        var statusRaw: String
        var errorMessage: String?
        var startedAt: Date
        var updatedAt: Date

        init(snapshot: AgentRunSnapshot) throws {
            runID = snapshot.runID
            graphName = snapshot.graphName
            startedAt = snapshot.startedAt
            nextNodeID = nil
            stateData = Data()
            usageData = Data()
            budgetData = Data()
            statusRaw = snapshot.status.rawValue
            updatedAt = snapshot.updatedAt
            try update(from: snapshot)
        }

        func update(from snapshot: AgentRunSnapshot) throws {
            let encoder = JSONEncoder()
            nextNodeID = snapshot.nextNodeID
            stateData = try encoder.encode(snapshot.state)
            usageData = try encoder.encode(snapshot.usage)
            budgetData = try encoder.encode(snapshot.budget)
            statusRaw = snapshot.status.rawValue
            errorMessage = snapshot.errorMessage
            updatedAt = snapshot.updatedAt
        }

        func snapshot() throws -> AgentRunSnapshot {
            let decoder = JSONDecoder()
            return AgentRunSnapshot(
                runID: runID,
                graphName: graphName,
                nextNodeID: nextNodeID,
                state: try decoder.decode(AgentRunState.self, from: stateData),
                usage: try decoder.decode(AgentUsage.self, from: usageData),
                budget: try decoder.decode(AgentBudget.self, from: budgetData),
                status: AgentRunStatus(rawValue: statusRaw) ?? .failed,
                errorMessage: errorMessage,
                startedAt: startedAt,
                updatedAt: updatedAt
            )
        }
    }
}

extension AgentRunSchemaV1 {
    /// One `LedgerEntry`, stored encoded so new entry kinds don't need a schema change.
    @Model
    final class AgentLedgerRecord {
        #Index<AgentLedgerRecord>([\.runID])

        var runID: UUID
        var sequence: Int
        var timestamp: Date
        var entryData: Data

        init(entry: LedgerEntry) throws {
            runID = entry.runID
            sequence = entry.sequence
            timestamp = entry.timestamp
            entryData = try JSONEncoder().encode(entry)
        }

        func entry() throws -> LedgerEntry {
            try JSONDecoder().decode(LedgerEntry.self, from: entryData)
        }
    }
}

/// Saves and loads run checkpoints and ledger entries in `agent-runs.store` in Application Support.
@MainActor
final class AgentRunStore {
    static let shared = AgentRunStore()

    let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    static var storeURL: URL {
        URL.applicationSupportDirectory.appending(path: "agent-runs.store")
    }

    /// - Parameter inMemory: for previews and tests.
    init(inMemory: Bool = false) {
        container = Self.makeContainer(inMemory: inMemory)
    }

    func save(_ snapshot: AgentRunSnapshot) throws {
        if let existing = try checkpoint(for: snapshot.runID) {
            try existing.update(from: snapshot)
        } else {
            context.insert(try AgentRunCheckpoint(snapshot: snapshot))
        }

        try context.save()
    }

    func snapshot(for runID: UUID) throws -> AgentRunSnapshot? {
        try checkpoint(for: runID)?.snapshot()
    }

    /// Most recently updated first. Rows that can't be decoded are skipped.
    func snapshots(graphName: String? = nil, limit: Int? = nil) throws -> [AgentRunSnapshot] {
        var descriptor = FetchDescriptor<AgentRunCheckpoint>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        if let graphName {
            descriptor.predicate = #Predicate { $0.graphName == graphName }
        }
        descriptor.fetchLimit = limit

        return try context.fetch(descriptor).compactMap { try? $0.snapshot() }
    }

    /// The newest run of `graphName` that can still be resumed, if any.
    func latestResumable(graphName: String) throws -> AgentRunSnapshot? {
        try snapshots(graphName: graphName).first { $0.status.isResumable }
    }

    func delete(runID: UUID) throws {
        if let checkpoint = try checkpoint(for: runID) {
            context.delete(checkpoint)
        }
        try context.delete(model: AgentLedgerRecord.self, where: #Predicate { $0.runID == runID })
        try context.save()
    }

    /// Drops runs that ended before `date`. Unfinished runs are kept so they can still resume.
    func deleteEndedRuns(before date: Date) throws {
        let running = AgentRunStatus.running.rawValue
        let paused = AgentRunStatus.paused.rawValue
        let ended = try context.fetch(FetchDescriptor<AgentRunCheckpoint>(
            predicate: #Predicate { $0.updatedAt < date && $0.statusRaw != running && $0.statusRaw != paused }
        ))

        for checkpoint in ended {
            let runID = checkpoint.runID
            try context.delete(model: AgentLedgerRecord.self, where: #Predicate { $0.runID == runID })
            context.delete(checkpoint)
        }
        try context.save()
    }

    // MARK: Ledger

    func append(_ entry: LedgerEntry) throws {
        context.insert(try AgentLedgerRecord(entry: entry))
        try context.save()
    }

    func ledgerEntries(runID: UUID) throws -> [LedgerEntry] {
        let descriptor = FetchDescriptor<AgentLedgerRecord>(
            predicate: #Predicate { $0.runID == runID },
            sortBy: [SortDescriptor(\.sequence)]
        )
        return try context.fetch(descriptor).compactMap { try? $0.entry() }
    }

    func ledgerEntryCount(runID: UUID) throws -> Int {
        try context.fetchCount(FetchDescriptor<AgentLedgerRecord>(predicate: #Predicate { $0.runID == runID }))
    }

    private func checkpoint(for runID: UUID) throws -> AgentRunCheckpoint? {
        var descriptor = FetchDescriptor<AgentRunCheckpoint>(predicate: #Predicate { $0.runID == runID })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private static func makeContainer(inMemory: Bool) -> ModelContainer {
        let schema = Schema(versionedSchema: AgentRunSchemaV1.self)
        let configuration = inMemory
            ? ModelConfiguration("AgentRuns", schema: schema, isStoredInMemoryOnly: true)
            : ModelConfiguration("AgentRuns", schema: schema, url: storeURL)

        if let container = try? ModelContainer(for: schema, configurations: configuration) {
            return container
        }

        // Checkpoints are disposable. If the file can't be opened (e.g. a schema change without
        // a migration), start over rather than break the app.
        LoggerService.main.error("[Agent] Couldn't open the agent run store. Recreating it.")
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(at: URL(filePath: storeURL.path(percentEncoded: false) + suffix))
        }

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            LoggerService.main.error("[Agent] Falling back to an in-memory run store: \(error)")
            let memory = ModelConfiguration("AgentRuns", schema: schema, isStoredInMemoryOnly: true)
            // An in-memory container with a valid schema doesn't fail in practice.
            return try! ModelContainer(for: schema, configurations: memory)
        }
    }
}
