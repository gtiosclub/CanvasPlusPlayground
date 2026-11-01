import Foundation
import Testing
@testable import CanvasPlusPlayground

@MainActor
struct ChangeEventRecoveryTests {
    @Test func failedLoadLeavesManagerUnloadedUntilRetry() async throws {
        let store = InMemoryChangeEventStore()
        let manager = makeManager(store)
        let item = try ChangeTestSupport.item()
        let observation = ChangeTestSupport.observation(item, oldValue: .text("A"), newValue: .text("B"))
        await store.failNextLoad()
        await #expect(throws: InMemoryChangeEventStore.Failure.simulated) { try await manager.load() }
        #expect(!manager.isLoaded)
        await #expect(throws: ChangeEventManager.ManagerError.notLoaded) { try await manager.apply(observation) }
        #expect(await store.saveCount == 0)

        try await manager.load()
        #expect(manager.isLoaded)
        try await manager.apply(observation)
        #expect(await store.saveCount == 1)
        #expect(manager.records(for: item).count == 1)
    }

    // NaN fails the snapshot equality check; infinity reaches the pre-save validation.
    @Test(arguments: [Double.nan, .infinity])
    func nonFiniteObservationIsRejectedBeforeSaving(points: Double) async throws {
        let store = InMemoryChangeEventStore()
        let manager = makeManager(store)
        try await manager.load()
        let item = try ChangeTestSupport.item()
        try await manager.apply(ChangeTestSupport.observation(item, field: .pointsPossible, oldValue: .number(100), newValue: .number(125)))
        let before = try manager.captureChanges(for: item)
        let saves = await store.saveCount
        let invalid = ChangeTestSupport.observation(item, field: .pointsPossible, oldValue: .number(125), newValue: .number(points))
        await #expect(throws: ChangeEventManager.ManagerError.invalidState) { try await manager.apply(invalid) }
        #expect(await store.saveCount == saves)
        #expect(try manager.captureChanges(for: item) == before)
    }

    @Test func quarantinesCorruptFileBeforeFirstSave() async throws {
        let root = try ChangeTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appending(path: "change-events.json")
        let corrupt = Data(#"{"formatVersion":1,"accounts":"truncated"#.utf8)
        try corrupt.write(to: url)
        let manager = ChangeEventManager(store: JSONChangeEventStore(fileURL: url), clock: { ChangeTestSupport.time })
        try await manager.load()
        #expect(manager.recoveryReason == .corrupt)

        let item = try ChangeTestSupport.item()
        try await manager.apply(ChangeTestSupport.observation(item, oldValue: .text("A"), newValue: .text("B")))
        let quarantined = try FileManager.default.contentsOfDirectory(atPath: root.path(percentEncoded: false))
            .filter { $0.hasPrefix("change-events.corrupt-") }
        #expect(quarantined.count == 1)
        let copy = try #require(quarantined.first.map { root.appending(path: $0) })
        #expect(try Data(contentsOf: copy) == corrupt)
        let reloaded = ChangeEventManager(store: JSONChangeEventStore(fileURL: url))
        try await reloaded.load()
        #expect(reloaded.recoveryReason == nil)
        #expect(reloaded.records(for: item).count == 1)
    }

    @Test func failedQuarantineLeavesManagerUnloaded() async throws {
        let store = InMemoryChangeEventStore(result: .empty(.corrupt))
        let manager = makeManager(store)
        await store.failNextQuarantine()
        await #expect(throws: InMemoryChangeEventStore.Failure.simulated) { try await manager.load() }
        #expect(!manager.isLoaded)
        let item = try ChangeTestSupport.item()
        let observation = ChangeTestSupport.observation(item, oldValue: .text("A"), newValue: .text("B"))
        await #expect(throws: ChangeEventManager.ManagerError.notLoaded) { try await manager.apply(observation) }
        #expect(await store.saveCount == 0)
    }

    private func makeManager(_ store: InMemoryChangeEventStore) -> ChangeEventManager {
        ChangeEventManager(store: store, clock: { ChangeTestSupport.time })
    }
}
