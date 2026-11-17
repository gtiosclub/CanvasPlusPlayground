import Foundation
@testable import CanvasPlusPlayground

enum ChangeTestSupport {
    static let time = Date(timeIntervalSince1970: 1_800_000_000)

    /// Creates an empty directory that the caller removes after the test.
    /// - Returns: A unique temporary directory.
    static func temporaryDirectory() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appending(path: "changes-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    /// Creates a fixture item with an independently scoped account and course.
    /// - Parameter userID: User owning the item.
    /// - Parameter courseID: Course containing the item.
    /// - Parameter itemID: Server item identifier.
    /// - Parameter itemType: Assignment or announcement identity.
    /// - Returns: The fully scoped item key.
    static func item(
        userID: String = "134",
        courseID: String = "123",
        itemID: String = "23",
        itemType: ChangeItemType = .assignment
    ) throws -> ChangeItemKey {
        ChangeItemKey(
            account: try AccountKey(rawHost: "canvas.example.edu", rawUserID: userID),
            courseID: courseID,
            itemType: itemType,
            itemID: itemID
        )
    }

    /// Creates comparison values for every tracked field.
    /// - Parameter field: Field whose fixture values are needed.
    /// - Returns: Distinct old and new values with the field's expected types.
    static func values(for field: ChangeField) -> (old: ChangeValue, new: ChangeValue) {
        switch field {
        case .itemAdded:
            return (.boolean(false), .boolean(true))
        case .dueAt, .lockAt, .unlockAt:
            return (.date(time), .date(time.addingTimeInterval(86_400)))
        case .name:
            return (.text("Old title"), .text("New title"))
        case .pointsPossible:
            return (.number(100), .number(125))
        case .descriptionHash:
            return (.descriptionHash("old-digest"), .descriptionHash("new-digest"))
        case .grade:
            return (
                .grade(.init(status: .graded, score: 80, grade: "80", gradedAt: time)),
                .grade(.init(status: .graded, score: 85, grade: "85", gradedAt: time.addingTimeInterval(60)))
            )
        }
    }

    /// Creates one snapshot and its corresponding field change.
    /// - Parameter itemKey: Item being observed.
    /// - Parameter field: Changed field.
    /// - Parameter oldValue: Previously observed value.
    /// - Parameter newValue: Latest observed value.
    /// - Returns: A consistent observation suitable for the manager.
    static func observation(
        _ itemKey: ChangeItemKey,
        field: ChangeField = .name,
        oldValue: ChangeValue,
        newValue: ChangeValue
    ) -> ChangeObservationResult {
        let title: String
        if field == .name, case .text(let name) = newValue {
            title = name
        } else {
            title = "Essay"
        }
        var values: [ChangeField: ChangeValue] = [.name: .text(title)]
        if field != .itemAdded { values[field] = newValue }
        return ChangeObservationResult(
            snapshots: [.init(itemKey: itemKey, displayTitle: title, values: values)],
            changes: [.init(itemKey: itemKey, field: field, oldValue: oldValue, newValue: newValue)]
        )
    }
}

actor InMemoryChangeEventStore: ChangeEventStore {
    private var result: ChangeStoreLoadResult
    private var shouldFailLoad = false
    private var shouldFailQuarantine = false
    private var shouldFailSave = false
    private var shouldSuspendSave = false
    private var suspendedSave: CheckedContinuation<Void, Never>?
    private var suspensionWaiters: [CheckedContinuation<Void, Never>] = []

    private(set) var loadCount = 0
    private(set) var saveCount = 0
    private(set) var quarantineCount = 0

    /// Creates isolated storage for one test.
    /// - Parameter result: State returned before the first successful save.
    init(result: ChangeStoreLoadResult = .empty(.missing)) {
        self.result = result
    }

    func load() async throws -> ChangeStoreLoadResult {
        loadCount += 1
        if shouldFailLoad {
            shouldFailLoad = false
            throw Failure.simulated
        }
        return result
    }

    func quarantine(timestamp: Date) async throws -> URL? {
        if shouldFailQuarantine {
            shouldFailQuarantine = false
            throw Failure.simulated
        }
        quarantineCount += 1
        result = .empty(.missing)
        return nil
    }

    /// Makes the next load fail without reporting missing or corrupt state.
    func failNextLoad() {
        shouldFailLoad = true
    }

    /// Makes the next quarantine fail, leaving corrupt state in place.
    func failNextQuarantine() {
        shouldFailQuarantine = true
    }

    func save(_ envelope: ChangeStoreEnvelope) async throws {
        if shouldSuspendSave {
            shouldSuspendSave = false
            await withCheckedContinuation { continuation in
                suspendedSave = continuation
                suspensionWaiters.forEach { $0.resume() }
                suspensionWaiters.removeAll()
            }
        }
        if shouldFailSave {
            shouldFailSave = false
            throw Failure.simulated
        }
        result = .loaded(envelope)
        saveCount += 1
    }

    /// Makes the next save fail before changing committed state.
    func failNextSave() {
        shouldFailSave = true
    }

    /// Suspends the next save until resumeSave is called.
    func suspendNextSave() {
        shouldSuspendSave = true
    }

    /// Waits until the controlled save reaches its suspension point.
    func waitForSuspendedSave() async {
        guard suspendedSave == nil else { return }
        await withCheckedContinuation { suspensionWaiters.append($0) }
    }

    /// Allows the controlled save to complete.
    func resumeSave() {
        suspendedSave?.resume()
        suspendedSave = nil
    }

    enum Failure: Error {
        case simulated
    }
}
