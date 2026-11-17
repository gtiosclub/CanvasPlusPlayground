@testable import CanvasPlusPlayground
import Foundation
import Testing

@MainActor
struct ChangeResetBoundaryTests {
    @Test func unloadedCaptureThrows() {
        let manager = ChangeEventManager(store: InMemoryChangeEventStore())
        #expect(throws: ChangeEventManager.ManagerError.notLoaded) { try manager.captureResetBoundary() }
    }

    @Test func emptyResetPersistsNewGeneration() async throws {
        let store = InMemoryChangeEventStore()
        let manager = ChangeEventManager(store: store)
        try await manager.load()
        let item = try ChangeTestSupport.item()
        let before = try manager.captureChanges(for: item)
        try await manager.reset()
        let after = try manager.captureChanges(for: item)
        #expect(after.resetGeneration != before.resetGeneration)
        #expect(after.throughRevision == before.throughRevision + 1)
        #expect(await store.saveCount == 1)
        guard case .loaded(let saved) = try await store.load() else {
            Issue.record("Empty reset was not persisted")
            return
        }
        #expect(saved.accounts.isEmpty)
        #expect(saved.resetGeneration == after.resetGeneration)
        #expect(saved.commitRevision == after.throughRevision)
        #expect(saved.formatVersion == ChangeStoreEnvelope.currentFormatVersion)
    }

    @Test func resetClearsEveryAccount() async throws {
        let store = InMemoryChangeEventStore()
        let manager = ChangeEventManager(store: store)
        try await manager.load()
        let boundary = try manager.captureResetBoundary()
        let accounts = try [
            AccountKey(rawHost: "canvas.example.edu", rawUserID: "134"),
            AccountKey(rawHost: "canvas.example.edu", rawUserID: "999"),
            AccountKey(rawHost: "other.example.edu", rawUserID: "134")
        ]
        for account in accounts {
            for family in ChangeResourceFamily.allCases {
                let type: ChangeItemType = family == .assignments ? .assignment : .announcement
                let key = ChangeItemKey(account: account, courseID: "123", itemType: type, itemID: "23")
                let observation = ChangeTestSupport.observation(key, oldValue: .text("A"), newValue: .text("B"))
                try await manager.apply(observation, boundary: boundary)
                try await manager.recordBaseline(
                    .init(courseID: "123", family: family),
                    for: account,
                    eligibility: .completeUnfilteredAllPagesSuccess,
                    boundary: boundary
                )
            }
        }
        let item = try ChangeTestSupport.item()
        let before = try manager.captureChanges(for: item)
        try await manager.reset()
        guard case .loaded(let saved) = try await store.load() else {
            Issue.record("Reset was not persisted")
            return
        }
        #expect(saved.accounts.isEmpty)
        #expect(saved.resetGeneration != before.resetGeneration)
        #expect(saved.commitRevision == before.throughRevision + 1)
        for account in accounts {
            #expect(manager.records(for: account).isEmpty)
            for family in ChangeResourceFamily.allCases {
                #expect(!manager.hasBaseline(.init(courseID: "123", family: family), for: account))
            }
        }
        let fresh = try manager.captureResetBoundary()
        let baseline = ChangeBaseline(courseID: "123", family: .assignments)
        try await manager.recordBaseline(baseline, for: item.account, eligibility: .completeUnfilteredAllPagesSuccess, boundary: fresh)
        #expect(manager.hasBaseline(baseline, for: item.account))
        #expect(try manager.captureChanges(for: item).throughRevision == saved.commitRevision + 1)
    }

    @Test func failedResetKeepsStateAndBoundary() async throws {
        let store = InMemoryChangeEventStore()
        let manager = ChangeEventManager(store: store)
        try await manager.load()
        let boundary = try manager.captureResetBoundary()
        let item = try ChangeTestSupport.item()
        let observation = ChangeTestSupport.observation(item, oldValue: .text("A"), newValue: .text("B"))
        try await manager.apply(observation, boundary: boundary)
        let baseline = ChangeBaseline(courseID: item.courseID, family: .assignments)
        try await manager.recordBaseline(baseline, for: item.account, eligibility: .completeUnfilteredAllPagesSuccess, boundary: boundary)
        let before = try manager.captureChanges(for: item)
        let saved = try await store.load()
        let saves = await store.saveCount
        await store.failNextSave()
        await #expect(throws: InMemoryChangeEventStore.Failure.simulated) { try await manager.reset() }
        #expect(try manager.captureChanges(for: item) == before)
        #expect(try manager.captureResetBoundary() == boundary)
        #expect(manager.hasBaseline(baseline, for: item.account))
        #expect(try await store.load() == saved)
        #expect(await store.saveCount == saves)
        let update = ChangeTestSupport.observation(item, oldValue: .text("B"), newValue: .text("C"))
        try await manager.apply(update, boundary: boundary)
        #expect(manager.records(for: item).first?.newValue == .text("C"))
    }

    // Proves old work is rejected after reset; it does not assert that queuing was observed.
    @Test(.timeLimit(.minutes(1)))
    func suspendedResetRejectsOldWork() async throws {
        let store = InMemoryChangeEventStore()
        let manager = ChangeEventManager(store: store)
        try await manager.load()
        let before = try manager.captureResetBoundary()
        let item = try ChangeTestSupport.item()
        let observation = ChangeTestSupport.observation(item, oldValue: .text("A"), newValue: .text("B"))
        let gate = try await store.suspendNextSave()
        let reset = Task { try await manager.reset() }
        try await store.waitForSuspendedSave(gate)
        let during = try manager.captureResetBoundary()
        #expect(during == before)
        let observationWork = Task { try await manager.apply(observation, boundary: before) }
        let baseline = ChangeBaseline(courseID: item.courseID, family: .assignments)
        let baselineWork = Task {
            try await manager.recordBaseline(baseline, for: item.account, eligibility: .completeUnfilteredAllPagesSuccess, boundary: during)
        }
        try await store.resumeSave(gate)
        try await reset.value
        await #expect(throws: ChangeEventManager.ManagerError.staleResetBoundary) { try await observationWork.value }
        await #expect(throws: ChangeEventManager.ManagerError.staleResetBoundary) { try await baselineWork.value }
        #expect(await store.saveCount == 1)
        #expect(manager.records(for: item).isEmpty)
        #expect(!manager.hasBaseline(baseline, for: item.account))
    }

    @Test func staleBoundaryPrecedesNoOps() async throws {
        let store = InMemoryChangeEventStore()
        let manager = ChangeEventManager(store: store)
        try await manager.load()
        let old = try manager.captureResetBoundary()
        let item = try ChangeTestSupport.item()
        let baseline = ChangeBaseline(courseID: item.courseID, family: .assignments)
        try await manager.reset()
        let fresh = try manager.captureResetBoundary()
        try await manager.recordBaseline(baseline, for: item.account, eligibility: .completeUnfilteredAllPagesSuccess, boundary: fresh)
        let saved = try await store.load()
        let saves = await store.saveCount
        await #expect(throws: ChangeEventManager.ManagerError.staleResetBoundary) {
            try await manager.apply(.init(snapshots: [], changes: []), boundary: old)
        }
        await #expect(throws: ChangeEventManager.ManagerError.staleResetBoundary) {
            try await manager.recordBaseline(baseline, for: item.account, eligibility: .completeUnfilteredAllPagesSuccess, boundary: old)
        }
        #expect(await store.saveCount == saves)
        #expect(try await store.load() == saved)
    }

    @Test(.timeLimit(.minutes(1)))
    func overlappingResetsSerialize() async throws {
        let store = InMemoryChangeEventStore()
        let manager = ChangeEventManager(store: store)
        try await manager.load()
        let item = try ChangeTestSupport.item()
        let before = try manager.captureChanges(for: item)
        let firstGate = try await store.suspendNextSave()
        let first = Task { try await manager.reset() }
        try await store.waitForSuspendedSave(firstGate)
        let second = Task { try await manager.reset() }
        let secondGate = try await store.suspendNextSave()
        #expect(try manager.captureChanges(for: item) == before)
        try await store.resumeSave(firstGate)
        try await first.value
        try await store.waitForSuspendedSave(secondGate)
        let middle = try manager.captureChanges(for: item)
        #expect(middle.throughRevision == before.throughRevision + 1)
        #expect(middle.resetGeneration != before.resetGeneration)
        try await store.resumeSave(secondGate)
        try await second.value
        let after = try manager.captureChanges(for: item)
        #expect(after.throughRevision == middle.throughRevision + 1)
        #expect(after.resetGeneration != middle.resetGeneration)
        #expect(await store.saveCount == 2)
    }

    @Test func finishedGateCannotSatisfyWait() async throws {
        let store = InMemoryChangeEventStore()
        let firstGate = try await store.suspendNextSave()
        let first = Task { try await store.save(ChangeStoreEnvelope()) }
        try await store.waitForSuspendedSave(firstGate)
        try await store.resumeSave(firstGate)
        try await first.value
        let secondGate = try await store.suspendNextSave()
        let second = Task { try await store.save(ChangeStoreEnvelope()) }
        try await store.waitForSuspendedSave(secondGate)
        await #expect(throws: InMemoryChangeEventStore.GateError.alreadyFinished) {
            try await store.waitForSuspendedSave(firstGate)
        }
        try await store.resumeSave(secondGate)
        try await second.value
        #expect(await store.saveCount == 2)
    }

    @Test func wrongResumeFailsFast() async throws {
        let store = InMemoryChangeEventStore()
        let active = try await store.suspendNextSave()
        let save = Task { try await store.save(ChangeStoreEnvelope()) }
        try await store.waitForSuspendedSave(active)
        let next = try await store.suspendNextSave()
        await #expect(throws: InMemoryChangeEventStore.GateError.wrongGate) { try await store.resumeSave(next) }
        await #expect(throws: InMemoryChangeEventStore.GateError.wrongGate) { try await save.value }
        #expect(await store.saveCount == 0)
    }

    @Test func overlappingSaveFailsFast() async throws {
        let store = InMemoryChangeEventStore()
        let firstGate = try await store.suspendNextSave()
        let first = Task { try await store.save(ChangeStoreEnvelope()) }
        try await store.waitForSuspendedSave(firstGate)
        _ = try await store.suspendNextSave()
        let second = Task { try await store.save(ChangeStoreEnvelope()) }
        await #expect(throws: InMemoryChangeEventStore.GateError.overlappingSaves) { try await second.value }
        await #expect(throws: InMemoryChangeEventStore.GateError.overlappingSaves) { try await first.value }
        #expect(await store.saveCount == 0)
    }

    // Defense in depth across resets; monotonic revisions also protect this genuine old capture.
    @Test func ignoresCaptureTakenBeforeReset() async throws {
        let store = InMemoryChangeEventStore()
        let manager = ChangeEventManager(store: store)
        try await manager.load()
        let oldBoundary = try manager.captureResetBoundary()
        let item = try ChangeTestSupport.item()
        let observation = ChangeTestSupport.observation(item, oldValue: .text("A"), newValue: .text("B"))
        try await manager.apply(observation, boundary: oldBoundary)
        let oldCapture = try manager.captureChanges(for: item)
        try await manager.reset()
        let fresh = try manager.captureResetBoundary()
        try await manager.apply(observation, boundary: fresh)
        let current = try manager.captureChanges(for: item)
        let saves = await store.saveCount
        #expect(current.resetGeneration != oldCapture.resetGeneration)
        #expect(!current.records.isEmpty)
        try await manager.acknowledge(oldCapture)
        #expect(try manager.captureChanges(for: item) == current)
        #expect(await store.saveCount == saves)
    }
}
