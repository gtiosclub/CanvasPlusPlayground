import Foundation
import Testing
@testable import CanvasPlusPlayground

@MainActor
struct ChangeEventManagerTests {
    @Test func loadsOnceAcrossConcurrentCallers() async throws {
        let store = InMemoryChangeEventStore()
        let manager = makeManager(store)
        async let first: Void = manager.load()
        async let second: Void = manager.load()
        _ = try await (first, second)
        #expect(manager.isLoaded)
        #expect(manager.recoveryReason == .missing)
        #expect(await store.loadCount == 1)
        #expect(await store.quarantineCount == 0)
    }

    @Test func rejectsEmptyName() async throws {
        let store = InMemoryChangeEventStore()
        let manager = makeManager(store)
        try await manager.load()
        let item = try ChangeTestSupport.item()
        let observation = ChangeObservationResult(
            snapshots: [.init(itemKey: item, displayTitle: "Essay", values: [.name: .null])],
            changes: [.init(itemKey: item, field: .name, oldValue: .text("Essay"), newValue: .null)]
        )
        await #expect(throws: ChangeEventManager.ManagerError.invalidState) { try await manager.apply(observation) }
        #expect(await store.saveCount == 0)
    }

    @Test func rejectsMutationBeforeLoading() async throws {
        let manager = makeManager(InMemoryChangeEventStore())
        let item = try ChangeTestSupport.item()
        let observation = ChangeTestSupport.observation(item, oldValue: .text("A"), newValue: .text("B"))
        await #expect(throws: ChangeEventManager.ManagerError.self) { try await manager.apply(observation) }
        #expect(manager.records(for: item).isEmpty)
    }

    @Test(arguments: ChangeField.allCases)
    func recordsAndRevertsEveryField(field: ChangeField) async throws {
        let manager = makeManager(InMemoryChangeEventStore())
        try await manager.load()
        let item = try ChangeTestSupport.item()
        let values = ChangeTestSupport.values(for: field)
        try await manager.apply(ChangeTestSupport.observation(item, field: field, oldValue: values.old, newValue: values.new))
        let record = try #require(manager.records(for: item).first)
        #expect(record.field == field)
        #expect(record.oldValue == values.old)
        #expect(record.newValue == values.new)
        #expect(record.firstDetectedAt == ChangeTestSupport.time)
        try await manager.apply(ChangeTestSupport.observation(item, field: field, oldValue: values.new, newValue: values.old))
        #expect(manager.records(for: item).isEmpty)
    }

    @Test func coalescesAndIgnoresRepeatedObservations() async throws {
        let store = InMemoryChangeEventStore()
        let manager = makeManager(store)
        try await manager.load()
        let item = try ChangeTestSupport.item()
        for (old, new) in [("A", "B"), ("B", "C"), ("C", "D")] {
            try await manager.apply(ChangeTestSupport.observation(item, oldValue: .text(old), newValue: .text(new)))
        }
        let capture = try manager.captureChanges(for: item)
        #expect(capture.records.count == 1)
        #expect(capture.records.first?.oldValue == .text("A"))
        #expect(capture.records.first?.newValue == .text("D"))
        let saves = await store.saveCount
        try await manager.apply(ChangeTestSupport.observation(item, oldValue: .text("C"), newValue: .text("D")))
        #expect(try manager.captureChanges(for: item) == capture)
        #expect(await store.saveCount == saves)
    }

    @Test func preservesFirstDetectionAcrossReloadAndCoalescing() async throws {
        let item = try ChangeTestSupport.item()
        let firstDate = ChangeTestSupport.time.addingTimeInterval(-3_600)
        let snapshot = ChangeSnapshot(itemKey: item, displayTitle: "B", values: [.name: .text("B")])
        let record = ChangeRecord(
            itemKey: item,
            field: .name,
            oldValue: .text("A"),
            newValue: .text("B"),
            firstDetectedAt: firstDate,
            lastDetectedAt: firstDate,
            revision: 1
        )
        let envelope = ChangeStoreEnvelope(
            commitRevision: 1,
            accounts: [.init(account: item.account, snapshots: [snapshot], records: [record])]
        )
        let manager = makeManager(InMemoryChangeEventStore(result: .loaded(envelope)))
        try await manager.load()
        try await manager.apply(ChangeTestSupport.observation(item, oldValue: .text("B"), newValue: .text("C")))
        let updated = try #require(manager.records(for: item).first)
        #expect(updated.oldValue == .text("A"))
        #expect(updated.firstDetectedAt == firstDate)
        #expect(updated.lastDetectedAt == ChangeTestSupport.time)
    }

    @Test(arguments: [ChangeField.dueAt, .lockAt, .unlockAt, .pointsPossible, .descriptionHash, .grade])
    func tracksExplicitNullTransitions(field: ChangeField) async throws {
        let manager = makeManager(InMemoryChangeEventStore())
        try await manager.load()
        let item = try ChangeTestSupport.item()
        let value = ChangeTestSupport.values(for: field).new
        try await manager.apply(ChangeTestSupport.observation(item, field: field, oldValue: .null, newValue: value))
        #expect(manager.records(for: item).first?.oldValue == .null)
        try await manager.apply(ChangeTestSupport.observation(item, field: field, oldValue: value, newValue: .null))
        #expect(manager.records(for: item).isEmpty)
    }

    @Test func acknowledgementPreservesNewerChanges() async throws {
        let manager = makeManager(InMemoryChangeEventStore())
        try await manager.load()
        let item = try ChangeTestSupport.item()
        try await manager.apply(ChangeTestSupport.observation(item, oldValue: .text("A"), newValue: .text("B")))
        let capture = try manager.captureChanges(for: item)
        try await manager.apply(ChangeTestSupport.observation(item, oldValue: .text("B"), newValue: .text("C")))
        try await manager.acknowledge(capture)
        #expect(manager.records(for: item).first?.newValue == .text("C"))
        #expect(capture.records.first?.newValue == .text("B"))
        try await manager.acknowledge(manager.captureChanges(for: item))
        #expect(manager.records(for: item).isEmpty)
    }

    @Test func newItemSuppressesEditsUntilAcknowledged() async throws {
        let manager = makeManager(InMemoryChangeEventStore())
        try await manager.load()
        let item = try ChangeTestSupport.item()
        let added = ChangeTestSupport.observation(item, field: .itemAdded, oldValue: .boolean(false), newValue: .boolean(true))
        let changes = [
            ChangeObservationResult.FieldChange(itemKey: item, field: .name, oldValue: .text("Old"), newValue: .text("Essay"))
        ] + added.changes
        try await manager.apply(.init(snapshots: added.snapshots, changes: changes))
        let capture = try manager.captureChanges(for: item)
        #expect(capture.records.map(\.field) == [.itemAdded])
        try await manager.apply(ChangeTestSupport.observation(item, oldValue: .text("Essay"), newValue: .text("Updated")))
        try await manager.acknowledge(capture)
        #expect(manager.records(for: item).map(\.field) == [.itemAdded])
        try await manager.acknowledge(manager.captureChanges(for: item))
        try await manager.apply(ChangeTestSupport.observation(item, oldValue: .text("Updated"), newValue: .text("Final")))
        #expect(manager.records(for: item).map(\.field) == [.name])
        #expect(manager.records(for: item).first?.oldValue == .text("Updated"))
    }

    @Test func queriesRespectAccountCourseAndDistinctItemScope() async throws {
        let manager = makeManager(InMemoryChangeEventStore())
        try await manager.load()
        let item = try ChangeTestSupport.item()
        let otherCourse = try ChangeTestSupport.item(courseID: "456")
        let otherAccount = try ChangeTestSupport.item(userID: "999")
        for key in [item, otherCourse, otherAccount] {
            try await manager.apply(ChangeTestSupport.observation(key, oldValue: .text("A"), newValue: .text("B")))
        }
        var points = ChangeTestSupport.observation(item, field: .pointsPossible, oldValue: .number(100), newValue: .number(125))
        points = .init(
            snapshots: [.init(itemKey: item, displayTitle: "B", values: [.pointsPossible: .number(125)])],
            changes: points.changes
        )
        try await manager.apply(points)
        #expect(manager.records(for: item).count == 2)
        #expect(manager.records(in: "123", account: item.account).count == 2)
        #expect(manager.unseenItemCount(in: "123", account: item.account) == 1)
        #expect(manager.records(for: item.account).count == 3)
        #expect(manager.records(for: otherAccount.account).count == 1)
        try await manager.acknowledge(manager.captureChanges(for: item))
        #expect(manager.records(for: item).isEmpty)
        #expect(manager.records(for: item.account).count == 1)
        #expect(manager.records(for: otherAccount.account).count == 1)
    }

    @Test func failedSavePreservesStateAndAllowsRetry() async throws {
        let store = InMemoryChangeEventStore()
        let manager = makeManager(store)
        try await manager.load()
        let item = try ChangeTestSupport.item()
        try await manager.apply(ChangeTestSupport.observation(item, oldValue: .text("A"), newValue: .text("B")))
        let before = try manager.captureChanges(for: item)
        let committed = try await store.load()
        let update = ChangeTestSupport.observation(item, oldValue: .text("B"), newValue: .text("C"))
        await store.failNextSave()
        await #expect(throws: InMemoryChangeEventStore.Failure.self) { try await manager.apply(update) }
        #expect(try manager.captureChanges(for: item) == before)
        #expect(try await store.load() == committed)
        try await manager.apply(update)
        #expect(manager.records(for: item).first?.newValue == .text("C"))
        await store.failNextSave()
        let capture = try manager.captureChanges(for: item)
        await #expect(throws: InMemoryChangeEventStore.Failure.self) { try await manager.acknowledge(capture) }
        #expect(try manager.captureChanges(for: item) == capture)
    }

    @Test func serializesOverlappingMutationsBeforePublishing() async throws {
        let store = InMemoryChangeEventStore()
        let manager = makeManager(store)
        try await manager.load()
        let item = try ChangeTestSupport.item()
        await store.suspendNextSave()
        let first = Task { @MainActor in
            try await manager.apply(ChangeTestSupport.observation(item, oldValue: .text("A"), newValue: .text("B")))
        }
        await store.waitForSuspendedSave()
        #expect(manager.records(for: item).isEmpty)
        let second = Task { @MainActor in
            try await manager.apply(ChangeTestSupport.observation(item, oldValue: .text("B"), newValue: .text("C")))
        }
        await Task.yield()
        #expect(manager.records(for: item).isEmpty)
        await store.resumeSave()
        try await first.value
        try await second.value
        #expect(manager.records(for: item).count == 1)
        #expect(manager.records(for: item).first?.oldValue == .text("A"))
        #expect(manager.records(for: item).first?.newValue == .text("C"))
    }

    @Test func ignoresCapturesFromAnotherGeneration() async throws {
        let manager = makeManager(InMemoryChangeEventStore())
        try await manager.load()
        let item = try ChangeTestSupport.item()
        try await manager.apply(ChangeTestSupport.observation(item, oldValue: .text("A"), newValue: .text("B")))
        let capture = ChangeEventManager.CapturedChanges(
            itemKey: item, records: [], resetGeneration: UUID(), throughRevision: .max
        )
        try await manager.acknowledge(capture)
        #expect(manager.records(for: item).count == 1)
    }

    @Test func rejectsDuplicatesAndRecoversCrossAccountStorage() async throws {
        let item = try ChangeTestSupport.item()
        let other = try ChangeTestSupport.item(userID: "999")
        let observation = ChangeTestSupport.observation(item, oldValue: .text("A"), newValue: .text("B"))
        let invalid = ChangeStoreEnvelope(accounts: [.init(account: other.account, snapshots: observation.snapshots)])
        let store = InMemoryChangeEventStore(result: .loaded(invalid))
        let manager = makeManager(store)
        try await manager.load()
        #expect(manager.recoveryReason == .corrupt)
        #expect(await store.quarantineCount == 1)
        #expect(manager.records(for: item).isEmpty)
        let duplicates = ChangeObservationResult(snapshots: observation.snapshots + observation.snapshots, changes: [])
        await #expect(throws: ChangeEventManager.ManagerError.self) { try await manager.apply(duplicates) }
        #expect(await store.saveCount == 0)
    }

    private func makeManager(_ store: InMemoryChangeEventStore) -> ChangeEventManager {
        ChangeEventManager(store: store, clock: { ChangeTestSupport.time })
    }
}
