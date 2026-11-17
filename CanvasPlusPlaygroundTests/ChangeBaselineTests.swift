@testable import CanvasPlusPlayground
import Foundation
import Testing

@MainActor
struct ChangeBaselineTests {
    @Test func unloadedQueriesReturnFalse() throws {
        let manager = ChangeEventManager(store: InMemoryChangeEventStore())
        let account = try ChangeTestSupport.item().account
        for family in ChangeResourceFamily.allCases {
            #expect(!manager.hasBaseline(.init(courseID: "123", family: family), for: account))
        }
    }

    @Test func unloadedRecordingThrows() async throws {
        let donor = ChangeEventManager(store: InMemoryChangeEventStore())
        try await donor.load()
        let boundary = try donor.captureResetBoundary()
        let store = InMemoryChangeEventStore()
        let manager = ChangeEventManager(store: store)
        let item = try ChangeTestSupport.item()
        let baseline = ChangeBaseline(courseID: item.courseID, family: .assignments)
        await #expect(throws: ChangeEventManager.ManagerError.notLoaded) {
            try await manager.recordBaseline(baseline, for: item.account, eligibility: .completeUnfilteredAllPagesSuccess, boundary: boundary)
        }
        #expect(await store.saveCount == 0)
        #expect(!manager.hasBaseline(baseline, for: item.account))
    }

    @Test func emptyCollectionIsIdempotent() async throws {
        let store = InMemoryChangeEventStore()
        let manager = ChangeEventManager(store: store)
        try await manager.load()
        let boundary = try manager.captureResetBoundary()
        let item = try ChangeTestSupport.item()
        let baseline = ChangeBaseline(courseID: item.courseID, family: .assignments)
        try await manager.recordBaseline(baseline, for: item.account, eligibility: .completeUnfilteredAllPagesSuccess, boundary: boundary)
        guard case .loaded(let saved) = try await store.load() else {
            Issue.record("Baseline was not persisted")
            return
        }
        #expect(saved.accounts.count == 1)
        #expect(saved.accounts.first?.snapshots.isEmpty == true)
        #expect(saved.accounts.first?.records.isEmpty == true)
        #expect(saved.accounts.first?.baselines == [baseline])
        let capture = try manager.captureChanges(for: item)
        let saves = await store.saveCount
        try await manager.recordBaseline(baseline, for: item.account, eligibility: .completeUnfilteredAllPagesSuccess, boundary: boundary)
        #expect(try manager.captureChanges(for: item) == capture)
        #expect(try await store.load() == .loaded(saved))
        #expect(await store.saveCount == saves)
        let reopened = ChangeEventManager(store: store)
        try await reopened.load()
        #expect(reopened.hasBaseline(baseline, for: item.account))
    }

    @Test(arguments: ChangeResourceFamily.allCases)
    func isolatesEveryScope(family: ChangeResourceFamily) async throws {
        let manager = ChangeEventManager(store: InMemoryChangeEventStore())
        try await manager.load()
        let boundary = try manager.captureResetBoundary()
        let account = try AccountKey(rawHost: "canvas.example.edu", rawUserID: "134")
        let baseline = ChangeBaseline(courseID: "123", family: family)
        try await manager.recordBaseline(baseline, for: account, eligibility: .completeUnfilteredAllPagesSuccess, boundary: boundary)
        for host in ["canvas.example.edu", "other.example.edu"] {
            for user in ["134", "999"] {
                let queryAccount = try AccountKey(rawHost: host, rawUserID: user)
                for course in ["123", "456", " 123 "] {
                    for queryFamily in ChangeResourceFamily.allCases {
                        let query = ChangeBaseline(courseID: course, family: queryFamily)
                        #expect(manager.hasBaseline(query, for: queryAccount) == (queryAccount == account && query == baseline))
                    }
                }
            }
        }
        let alias = try AccountKey(rawHost: "https://CANVAS.example.edu:443/", rawUserID: " 134 ")
        #expect(manager.hasBaseline(baseline, for: alias))
    }

    @Test(arguments: ChangeEventManager.CollectionEligibility.RejectionReason.allCases)
    func rejectsEachReasonExactly(reason: ChangeEventManager.CollectionEligibility.RejectionReason) async throws {
        for alreadyExists in [false, true] {
            let store = InMemoryChangeEventStore()
            let manager = ChangeEventManager(store: store)
            try await manager.load()
            let boundary = try manager.captureResetBoundary()
            let item = try ChangeTestSupport.item()
            let baseline = ChangeBaseline(courseID: item.courseID, family: .assignments)
            if alreadyExists {
                try await manager.recordBaseline(
                    baseline, for: item.account, eligibility: .completeUnfilteredAllPagesSuccess, boundary: boundary
                )
            }
            let saved = try await store.load()
            let capture = try manager.captureChanges(for: item)
            let saves = await store.saveCount
            await #expect(throws: ChangeEventManager.ManagerError.collectionNotEligible(reason)) {
                try await manager.recordBaseline(baseline, for: item.account, eligibility: .rejected(reason), boundary: boundary)
            }
            #expect(await store.saveCount == saves)
            #expect(try await store.load() == saved)
            #expect(try manager.captureChanges(for: item) == capture)
            #expect(manager.hasBaseline(baseline, for: item.account) == alreadyExists)
        }
    }

    @Test(arguments: [
        [ChangeBaseline(courseID: "123", family: .assignments), ChangeBaseline(courseID: "123", family: .assignments)],
        [ChangeBaseline(courseID: "", family: .assignments)],
        [ChangeBaseline(courseID: " \n", family: .announcements)]
    ])
    func quarantinesInvalidBaselines(baselines: [ChangeBaseline]) async throws {
        let item = try ChangeTestSupport.item()
        let saved = ChangeStoreEnvelope(accounts: [.init(account: item.account, baselines: baselines)])
        let store = InMemoryChangeEventStore(result: .loaded(saved))
        let manager = ChangeEventManager(store: store)
        try await manager.load()
        #expect(manager.recoveryReason == .corrupt)
        #expect(await store.quarantineCount == 1)
        #expect(await store.saveCount == 0)
        #expect(try manager.captureChanges(for: item).throughRevision == 0)
        for baseline in baselines {
            #expect(!manager.hasBaseline(baseline, for: item.account))
        }
    }

    @Test(arguments: ["", " \n"])
    func rejectsBlankCourse(course: String) async throws {
        let store = InMemoryChangeEventStore()
        let manager = ChangeEventManager(store: store)
        try await manager.load()
        let boundary = try manager.captureResetBoundary()
        let item = try ChangeTestSupport.item()
        let baseline = ChangeBaseline(courseID: course, family: .assignments)
        let before = try manager.captureChanges(for: item)
        await #expect(throws: ChangeEventManager.ManagerError.invalidState) {
            try await manager.recordBaseline(baseline, for: item.account, eligibility: .completeUnfilteredAllPagesSuccess, boundary: boundary)
        }
        #expect(await store.saveCount == 0)
        #expect(try manager.captureChanges(for: item) == before)
        #expect(!manager.hasBaseline(baseline, for: item.account))
    }

    @Test func failedSavePublishesNothing() async throws {
        let store = InMemoryChangeEventStore()
        let manager = ChangeEventManager(store: store)
        try await manager.load()
        let boundary = try manager.captureResetBoundary()
        let item = try ChangeTestSupport.item()
        let baseline = ChangeBaseline(courseID: item.courseID, family: .assignments)
        let saved = try await store.load()
        let capture = try manager.captureChanges(for: item)
        await store.failNextSave()
        await #expect(throws: InMemoryChangeEventStore.Failure.simulated) {
            try await manager.recordBaseline(baseline, for: item.account, eligibility: .completeUnfilteredAllPagesSuccess, boundary: boundary)
        }
        #expect(!manager.hasBaseline(baseline, for: item.account))
        #expect(try await store.load() == saved)
        #expect(try manager.captureChanges(for: item) == capture)
        #expect(await store.saveCount == 0)
        try await manager.recordBaseline(baseline, for: item.account, eligibility: .completeUnfilteredAllPagesSuccess, boundary: boundary)
        #expect(manager.hasBaseline(baseline, for: item.account))
    }
}
