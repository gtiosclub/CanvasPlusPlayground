import Foundation
import Testing
@testable import CanvasPlusPlayground

struct ChangeEventStoreTests {
    @Test func missingFileDoesNotCreateStorage() async throws {
        let root = try ChangeTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appending(path: "nested/changes.json")
        let result = try await JSONChangeEventStore(fileURL: url).load()
        #expect(result == .empty(.missing))
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test func roundTripsAndReopensPopulatedState() async throws {
        let root = try ChangeTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appending(path: "nested/changes.json")
        let item = try ChangeTestSupport.item()
        let observation = ChangeTestSupport.observation(item, oldValue: .text("Old"), newValue: .text("Essay"))
        let envelope = ChangeStoreEnvelope(accounts: [.init(account: item.account, snapshots: observation.snapshots)])
        try await JSONChangeEventStore(fileURL: url).save(envelope)
        let reopened = try await JSONChangeEventStore(fileURL: url).load()
        #expect(reopened == .loaded(envelope))
    }

    @Test func defaultFileUsesBundleSpecificFolder() {
        let folder = JSONChangeEventStore.defaultFileURL.deletingLastPathComponent()
        #expect(folder.lastPathComponent == Bundle.main.bundleIdentifier)
        #expect(folder.deletingLastPathComponent() == URL.applicationSupportDirectory)
    }

    @Test func writesDeterministicFieldSortedJSON() async throws {
        let root = try ChangeTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let item = try ChangeTestSupport.item()
        var forward: [ChangeField: ChangeValue] = [:]
        var reverse: [ChangeField: ChangeValue] = [:]
        let fields = ChangeField.allCases.filter { $0 != .itemAdded }
        for field in fields { forward[field] = ChangeTestSupport.values(for: field).new }
        for field in fields.reversed() { reverse[field] = ChangeTestSupport.values(for: field).new }
        let urls = [root.appending(path: "a.json"), root.appending(path: "b.json")]
        for (url, values) in zip(urls, [forward, reverse]) {
            let snapshot = ChangeSnapshot(itemKey: item, displayTitle: "Essay", values: values)
            let generation = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
            let envelope = ChangeStoreEnvelope(resetGeneration: generation, accounts: [.init(account: item.account, snapshots: [snapshot])])
            try await JSONChangeEventStore(fileURL: url).save(envelope)
            #expect(try await JSONChangeEventStore(fileURL: url).load() == .loaded(envelope))
        }
        let bytes = try urls.map { try Data(contentsOf: $0) }
        #expect(bytes[0] == bytes[1])
        #expect(try #require(String(bytes: bytes[0], encoding: .utf8)).contains("_0") == false)
    }

    @Test func quarantineMovesFileWithOriginalBytes() async throws {
        let root = try ChangeTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appending(path: "change-events.json")
        let store = JSONChangeEventStore(fileURL: url)
        #expect(try await store.quarantine(timestamp: ChangeTestSupport.time) == nil)
        let data = Data("not JSON".utf8)
        try data.write(to: url)
        let moved = try #require(try await store.quarantine(timestamp: ChangeTestSupport.time))
        #expect(moved.lastPathComponent == "change-events.corrupt-20270115T080000000Z.json")
        #expect(try Data(contentsOf: moved) == data)
        #expect(try await store.load() == .empty(.missing))
    }

    @Test(arguments: ["not JSON", "{}", #"{"formatVersion":1}"#, #"{"formatVersion":0}"#, #"{"formatVersion":-1}"#])
    func reportsCorruptionWithoutOverwriting(contents: String) async throws {
        let root = try ChangeTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appending(path: "changes.json")
        let data = Data(contents.utf8)
        try data.write(to: url)
        let result = try await JSONChangeEventStore(fileURL: url).load()
        #expect(result == .empty(.corrupt))
        #expect(try Data(contentsOf: url) == data)
    }

    @Test func preservesUnsupportedFormat() async throws {
        let root = try ChangeTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appending(path: "changes.json")
        let data = Data(#"{"formatVersion":99,"futureShape":[]}"#.utf8)
        try data.write(to: url)
        let store = JSONChangeEventStore(fileURL: url)
        await #expect(throws: ChangeStoreError.self) { try await store.load() }
        #expect(try Data(contentsOf: url) == data)
    }

    @Test func readFailureIsNotReportedAsCorruption() async throws {
        let root = try ChangeTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = JSONChangeEventStore(fileURL: root)
        await #expect(throws: (any Error).self) { try await store.load() }
    }

    @Test func encodingFailurePreservesPreviousFile() async throws {
        let root = try ChangeTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appending(path: "changes.json")
        let store = JSONChangeEventStore(fileURL: url)
        try await store.save(ChangeStoreEnvelope())
        let original = try Data(contentsOf: url)
        let item = try ChangeTestSupport.item()
        let invalid = ChangeSnapshot(itemKey: item, displayTitle: "Essay", values: [.pointsPossible: .number(.nan)])
        let envelope = ChangeStoreEnvelope(accounts: [.init(account: item.account, snapshots: [invalid])])
        await #expect(throws: (any Error).self) { try await store.save(envelope) }
        #expect(try Data(contentsOf: url) == original)
    }

    @Test func writeFailurePreservesPreviousFile() async throws {
        let root = try ChangeTestSupport.temporaryDirectory()
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: root.path)
            try? FileManager.default.removeItem(at: root)
        }
        let url = root.appending(path: "changes.json")
        let store = JSONChangeEventStore(fileURL: url)
        try await store.save(ChangeStoreEnvelope())
        let original = try Data(contentsOf: url)
        try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: root.path)
        await #expect(throws: (any Error).self) { try await store.save(ChangeStoreEnvelope(commitRevision: 1)) }
        #expect(try Data(contentsOf: url) == original)
    }
}
