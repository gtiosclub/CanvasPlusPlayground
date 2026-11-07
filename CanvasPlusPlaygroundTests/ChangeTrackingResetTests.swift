@testable import CanvasPlusPlayground
import Foundation
import Testing

@MainActor
struct ChangeTrackingResetTests {
    @Test(arguments: FailureStage.allCases)
    func requiredFailureNeverClears(stage: FailureStage) async throws {
        let store = await failingStore(stage)
        let manager = ChangeEventManager(store: store)
        var clears = 0
        await #expect(throws: InMemoryChangeEventStore.Failure.simulated) {
            try await ChangeTrackingReset.resetThenClear(manager: manager, policy: .required) { clears += 1 }
        }
        #expect(clears == 0)
        #expect(await store.saveCount == 0)
        #expect(manager.isLoaded == (stage == .save))
    }

    @Test(arguments: FailureStage.allCases)
    func bestEffortFailureStillClears(stage: FailureStage) async throws {
        let store = await failingStore(stage)
        let manager = ChangeEventManager(store: store)
        var clears = 0
        try await ChangeTrackingReset.resetThenClear(manager: manager, policy: .bestEffort) { clears += 1 }
        #expect(clears == 1)
        #expect(await store.saveCount == 0)
        #expect(manager.isLoaded == (stage == .save))
    }

    @Test(.timeLimit(.minutes(1)))
    func resetCompletesBeforeClear() async throws {
        let store = InMemoryChangeEventStore()
        let manager = ChangeEventManager(store: store)
        try await manager.load()
        let item = try ChangeTestSupport.item()
        let before = try manager.captureChanges(for: item)
        var atClear: ChangeEventManager.CapturedChanges?
        let gate = try await store.suspendNextSave()
        let task = Task {
            try await ChangeTrackingReset.resetThenClear(manager: manager, policy: .required) {
                atClear = try manager.captureChanges(for: item)
            }
        }
        try await store.waitForSuspendedSave(gate)
        #expect(atClear == nil)
        #expect(try manager.captureChanges(for: item) == before)
        try await store.resumeSave(gate)
        try await task.value
        let captured = try #require(atClear)
        #expect(captured.resetGeneration != before.resetGeneration)
        #expect(captured.throughRevision == before.throughRevision + 1)
        #expect(await store.saveCount == 1)
    }

    @Test(arguments: [ChangeTrackingReset.Policy.required, .bestEffort])
    func preservesNewerFormat(policy: ChangeTrackingReset.Policy) async throws {
        let root = try ChangeTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appending(path: "changes.json")
        let bytes = Data(#"{"formatVersion":99,"futureShape":[]}"#.utf8)
        try bytes.write(to: url)
        let manager = ChangeEventManager(store: JSONChangeEventStore(fileURL: url))
        var clears = 0
        switch policy {
        case .required:
            await #expect(throws: ChangeStoreError.unsupportedFormat(99)) {
                try await ChangeTrackingReset.resetThenClear(manager: manager, policy: policy) { clears += 1 }
            }
            #expect(clears == 0)
        case .bestEffort:
            try await ChangeTrackingReset.resetThenClear(manager: manager, policy: policy) { clears += 1 }
            #expect(clears == 1)
        }
        #expect(!manager.isLoaded)
        #expect(try Data(contentsOf: url) == bytes)
        #expect(try FileManager.default.contentsOfDirectory(atPath: root.path) == ["changes.json"])
    }

    @Test(arguments: [ChangeTrackingReset.Policy.required, .bestEffort])
    func preservesFailedQuarantine(policy: ChangeTrackingReset.Policy) async throws {
        let root = try ChangeTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appending(path: "change-events.json")
        let stamp = ChangeTestSupport.time.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true))
            .filter { $0.isLetter || $0.isNumber }
        let collision = root.appending(path: "change-events.corrupt-\(stamp).json")
        let corrupt = Data("corrupt".utf8)
        let existing = Data("existing quarantine".utf8)
        try corrupt.write(to: url)
        try existing.write(to: collision)
        let manager = ChangeEventManager(store: JSONChangeEventStore(fileURL: url), clock: { ChangeTestSupport.time })
        var clears = 0
        switch policy {
        case .required:
            await #expect(throws: (any Error).self) {
                try await ChangeTrackingReset.resetThenClear(manager: manager, policy: policy) { clears += 1 }
            }
            #expect(clears == 0)
        case .bestEffort:
            try await ChangeTrackingReset.resetThenClear(manager: manager, policy: policy) { clears += 1 }
            #expect(clears == 1)
        }
        #expect(!manager.isLoaded)
        #expect(try Data(contentsOf: url) == corrupt)
        #expect(try Data(contentsOf: collision) == existing)
        #expect(try FileManager.default.contentsOfDirectory(atPath: root.path).count == 2)
    }

    @Test(arguments: [ChangeTrackingReset.Policy.required, .bestEffort])
    func clearErrorsAlwaysPropagate(policy: ChangeTrackingReset.Policy) async throws {
        let store = InMemoryChangeEventStore()
        let manager = ChangeEventManager(store: store)
        await #expect(throws: ClearFailure.simulated) {
            try await ChangeTrackingReset.resetThenClear(manager: manager, policy: policy) { throw ClearFailure.simulated }
        }
        #expect(manager.isLoaded)
        #expect(await store.saveCount == 1)
    }

    @Test func readyLoadKeepsResetState() async throws {
        let store = InMemoryChangeEventStore()
        let manager = ChangeEventManager(store: store)
        try await ChangeTrackingReset.resetThenClear(manager: manager, policy: .bestEffort) { }
        let item = try ChangeTestSupport.item()
        let after = try manager.captureChanges(for: item)
        async let first: Void = manager.load()
        async let second: Void = manager.load()
        _ = try await (first, second)
        #expect(await store.loadCount == 1)
        #expect(try manager.captureChanges(for: item) == after)
        let boundary = try manager.captureResetBoundary()
        let baseline = ChangeBaseline(courseID: item.courseID, family: .assignments)
        try await manager.recordBaseline(baseline, for: item.account, eligibility: .completeUnfilteredAllPagesSuccess, boundary: boundary)
        #expect(manager.hasBaseline(baseline, for: item.account))
    }

    @Test(arguments: FailureStage.allCases)
    func clearCacheFailureNeverClears(stage: FailureStage) async throws {
        let store = await failingStore(stage)
        let manager = ChangeEventManager(store: store)
        var clears = 0
        await #expect(throws: InMemoryChangeEventStore.Failure.simulated) {
            try await ChangeTrackingReset.clearCache(manager: manager) { clears += 1 }
        }
        #expect(clears == 0)
        #expect(await store.saveCount == 0)
    }

    @Test(arguments: FailureStage.allCases)
    func recoverStorageFailureStillErases(stage: FailureStage) async throws {
        let store = await failingStore(stage)
        let manager = ChangeEventManager(store: store)
        var erases = 0
        try await ChangeTrackingReset.recoverStorage(manager: manager) { erases += 1 }
        #expect(erases == 1)
        #expect(await store.saveCount == 0)
    }

    @Test func recoverStoragePreservesNewerFormat() async throws {
        let root = try ChangeTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appending(path: "changes.json")
        let bytes = Data(#"{"formatVersion":99,"futureShape":[]}"#.utf8)
        try bytes.write(to: url)
        let manager = ChangeEventManager(store: JSONChangeEventStore(fileURL: url))
        var erases = 0
        try await ChangeTrackingReset.recoverStorage(manager: manager) { erases += 1 }
        #expect(erases == 1)
        #expect(!manager.isLoaded)
        #expect(try Data(contentsOf: url) == bytes)
        #expect(try FileManager.default.contentsOfDirectory(atPath: root.path) == ["changes.json"])
    }

    @Test(arguments: [false, true])
    func recoverStorageEraseFailurePropagates(trackingFails: Bool) async throws {
        let store = InMemoryChangeEventStore()
        if trackingFails { await store.failNextLoad() }
        let manager = ChangeEventManager(store: store)
        var erases = 0
        await #expect(throws: ClearFailure.simulated) {
            try await ChangeTrackingReset.recoverStorage(manager: manager) {
                erases += 1
                throw ClearFailure.simulated
            }
        }
        #expect(erases == 1)
        #expect(await store.saveCount == (trackingFails ? 0 : 1))
    }

    @Test(.timeLimit(.minutes(1)), arguments: [false, true])
    func wrappersResetBeforeClear(recovering: Bool) async throws {
        let store = InMemoryChangeEventStore()
        let manager = ChangeEventManager(store: store)
        try await manager.load()
        let item = try ChangeTestSupport.item()
        let before = try manager.captureChanges(for: item)
        var atClear: ChangeEventManager.CapturedChanges?
        let gate = try await store.suspendNextSave()
        let task = Task {
            let clear = { atClear = try manager.captureChanges(for: item) }
            if recovering {
                try await ChangeTrackingReset.recoverStorage(manager: manager, erase: clear)
            } else {
                try await ChangeTrackingReset.clearCache(manager: manager, clear: clear)
            }
        }
        try await store.waitForSuspendedSave(gate)
        #expect(atClear == nil)
        #expect(try manager.captureChanges(for: item) == before)
        try await store.resumeSave(gate)
        try await task.value
        let captured = try #require(atClear)
        #expect(captured.resetGeneration != before.resetGeneration)
        #expect(captured.throughRevision == before.throughRevision + 1)
        #expect(await store.saveCount == 1)
    }

    private func failingStore(_ stage: FailureStage) async -> InMemoryChangeEventStore {
        let store = InMemoryChangeEventStore(result: stage == .quarantine ? .empty(.corrupt) : .empty(.missing))
        switch stage {
        case .load:
            await store.failNextLoad()
        case .save:
            await store.failNextSave()
        case .quarantine:
            await store.failNextQuarantine()
        }
        return store
    }

    enum FailureStage: CaseIterable, Sendable {
        case load
        case save
        case quarantine
    }

    enum ClearFailure: Error {
        case simulated
    }
}
