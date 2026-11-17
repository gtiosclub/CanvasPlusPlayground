@testable import CanvasPlusPlayground
import Foundation
import Testing

@MainActor
struct ChangeRevisionTests {
    @Test func quarantinesMaxRevisionOnLoad() async throws {
        let root = try ChangeTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appending(path: "change-events.json")
        let bytes = try JSONEncoder().encode(ChangeStoreEnvelope(commitRevision: .max))
        try bytes.write(to: url)
        let manager = ChangeEventManager(store: JSONChangeEventStore(fileURL: url), clock: { ChangeTestSupport.time })
        try await manager.load()
        #expect(manager.isLoaded)
        #expect(manager.recoveryReason == .corrupt)
        #expect(!FileManager.default.fileExists(atPath: url.path))
        let copies = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
        #expect(copies.count == 1)
        let copy = try #require(copies.first)
        #expect(copy.lastPathComponent.hasPrefix("change-events.corrupt-"))
        #expect(try Data(contentsOf: copy) == bytes)
        #expect(try manager.captureChanges(for: ChangeTestSupport.item()).throughRevision == 0)
    }

    @Test(arguments: Mutation.allCases)
    func exhaustionRollsBackEveryMutation(mutation: Mutation) async throws {
        let item = try ChangeTestSupport.item()
        let observation = ChangeTestSupport.observation(item, oldValue: .text("A"), newValue: .text("B"))
        let baseline = ChangeBaseline(courseID: item.courseID, family: .assignments)
        let added = ChangeBaseline(courseID: item.courseID, family: .announcements)
        let record = ChangeRecord(
            itemKey: item,
            field: .name,
            oldValue: .text("A"),
            newValue: .text("B"),
            firstDetectedAt: ChangeTestSupport.time,
            lastDetectedAt: ChangeTestSupport.time,
            revision: 1
        )
        let saved = ChangeStoreEnvelope(
            commitRevision: UInt64.max - 1,
            accounts: [.init(account: item.account, snapshots: observation.snapshots, records: [record], baselines: [baseline])]
        )
        let store = InMemoryChangeEventStore(result: .loaded(saved))
        let manager = ChangeEventManager(store: store)
        try await manager.load()
        let boundary = try manager.captureResetBoundary()
        let before = try manager.captureChanges(for: item)
        let update = ChangeTestSupport.observation(item, oldValue: .text("B"), newValue: .text("C"))
        #expect(manager.recoveryReason == nil)
        #expect(!manager.hasBaseline(added, for: item.account))
        await #expect(throws: ChangeEventManager.ManagerError.revisionExhausted) {
            switch mutation {
            case .observation:
                try await manager.apply(update, boundary: boundary)
            case .baseline:
                try await manager.recordBaseline(added, for: item.account, eligibility: .completeUnfilteredAllPagesSuccess, boundary: boundary)
            case .acknowledgement:
                try await manager.acknowledge(before)
            case .reset:
                try await manager.reset()
            }
        }
        #expect(await store.saveCount == 0)
        #expect(try await store.load() == .loaded(saved))
        #expect(try manager.captureChanges(for: item) == before)
        #expect(try manager.captureResetBoundary() == boundary)
        #expect(manager.hasBaseline(baseline, for: item.account))
        #expect(!manager.hasBaseline(added, for: item.account))
    }

    @Test func repeatedBaselineDoesNotAdvance() async throws {
        let item = try ChangeTestSupport.item()
        let baseline = ChangeBaseline(courseID: item.courseID, family: .assignments)
        let saved = ChangeStoreEnvelope(
            commitRevision: UInt64.max - 1, accounts: [.init(account: item.account, baselines: [baseline])]
        )
        let store = InMemoryChangeEventStore(result: .loaded(saved))
        let manager = ChangeEventManager(store: store)
        try await manager.load()
        let boundary = try manager.captureResetBoundary()
        let before = try manager.captureChanges(for: item)
        try await manager.recordBaseline(baseline, for: item.account, eligibility: .completeUnfilteredAllPagesSuccess, boundary: boundary)
        #expect(await store.saveCount == 0)
        #expect(try await store.load() == .loaded(saved))
        #expect(try manager.captureChanges(for: item) == before)
    }

    @Test func persistsLastAvailableRevision() async throws {
        let root = try ChangeTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appending(path: "changes.json")
        let store = JSONChangeEventStore(fileURL: url)
        try await store.save(ChangeStoreEnvelope(commitRevision: UInt64.max - 2))
        let manager = ChangeEventManager(store: store)
        try await manager.load()
        let boundary = try manager.captureResetBoundary()
        let item = try ChangeTestSupport.item()
        let first = ChangeBaseline(courseID: item.courseID, family: .assignments)
        try await manager.recordBaseline(first, for: item.account, eligibility: .completeUnfilteredAllPagesSuccess, boundary: boundary)
        guard case .loaded(let saved) = try await store.load() else {
            Issue.record("Last available revision was not persisted")
            return
        }
        #expect(saved.commitRevision == UInt64.max - 1)
        #expect(saved.accounts.first?.baselines == [first])
        let bytes = try Data(contentsOf: url)
        let reopened = ChangeEventManager(store: JSONChangeEventStore(fileURL: url))
        try await reopened.load()
        #expect(reopened.recoveryReason == nil)
        #expect(reopened.hasBaseline(first, for: item.account))
        #expect(try FileManager.default.contentsOfDirectory(atPath: root.path) == ["changes.json"])
        let before = try reopened.captureChanges(for: item)
        let fresh = try reopened.captureResetBoundary()
        let second = ChangeBaseline(courseID: item.courseID, family: .announcements)
        await #expect(throws: ChangeEventManager.ManagerError.revisionExhausted) {
            try await reopened.recordBaseline(second, for: item.account, eligibility: .completeUnfilteredAllPagesSuccess, boundary: fresh)
        }
        #expect(!reopened.hasBaseline(second, for: item.account))
        #expect(try reopened.captureChanges(for: item) == before)
        #expect(try Data(contentsOf: url) == bytes)
    }

    @Test(arguments: [false, true])
    func maxSaveRejectsBeforeEncoding(unencodable: Bool) async throws {
        let root = try ChangeTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appending(path: "changes.json")
        let store = JSONChangeEventStore(fileURL: url)
        try await store.save(ChangeStoreEnvelope())
        let original = try Data(contentsOf: url)
        let files = try FileManager.default.contentsOfDirectory(atPath: root.path).sorted()
        let item = try ChangeTestSupport.item()
        let snapshot = ChangeSnapshot(
            itemKey: item, displayTitle: "Essay", values: [.pointsPossible: .number(unencodable ? .nan : 100)]
        )
        let invalid = ChangeStoreEnvelope(
            commitRevision: .max, accounts: [.init(account: item.account, snapshots: [snapshot])]
        )
        await #expect(throws: ChangeStoreError.revisionExhausted) { try await store.save(invalid) }
        #expect(try Data(contentsOf: url) == original)
        #expect(try FileManager.default.contentsOfDirectory(atPath: root.path).sorted() == files)
    }

    enum Mutation: CaseIterable, Sendable {
        case observation
        case baseline
        case acknowledgement
        case reset
    }
}
