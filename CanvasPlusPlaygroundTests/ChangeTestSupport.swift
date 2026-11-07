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
    private var armedSave: SaveGate?
    private var suspendedSave: (gate: SaveGate, continuation: CheckedContinuation<Void, Error>)?
    private var suspensionWaiters: [SaveGate: [CheckedContinuation<Void, Error>]] = [:]
    private var completedGates: Set<SaveGate> = []

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
        if let gate = armedSave {
            guard suspendedSave == nil else {
                abortGates(.overlappingSaves)
                throw GateError.overlappingSaves
            }
            armedSave = nil
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                suspendedSave = (gate, continuation)
                suspensionWaiters.removeValue(forKey: gate)?.forEach { $0.resume() }
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

    /// Arms a distinct gate for the next save, including while an earlier save is suspended.
    /// - Returns: Ticket required to wait for and resume that save.
    func suspendNextSave() throws -> SaveGate {
        guard armedSave == nil else {
            abortGates(.alreadyArmed)
            throw GateError.alreadyArmed
        }
        let gate = SaveGate()
        armedSave = gate
        return gate
    }

    /// Waits for the specified save rather than any previous suspension.
    /// - Parameters:
    ///   - gate: Ticket returned when the save was armed.
    func waitForSuspendedSave(_ gate: SaveGate) async throws {
        guard !completedGates.contains(gate) else { throw GateError.alreadyFinished }
        if suspendedSave?.gate == gate { return }
        guard armedSave == gate else { throw GateError.unknownGate }
        try await withCheckedThrowingContinuation { suspensionWaiters[gate, default: []].append($0) }
    }

    /// Resumes exactly one active save; incorrect tickets fail and release blocked operations.
    /// - Parameters:
    ///   - gate: Ticket identifying the suspended save.
    func resumeSave(_ gate: SaveGate) throws {
        guard let suspended = suspendedSave, suspended.gate == gate else {
            abortGates(.wrongGate)
            throw GateError.wrongGate
        }
        suspendedSave = nil
        completedGates.insert(gate)
        suspended.continuation.resume()
    }

    private func abortGates(_ error: GateError) {
        let suspended = suspendedSave
        suspendedSave = nil
        if let armedSave { completedGates.insert(armedSave) }
        if let suspended { completedGates.insert(suspended.gate) }
        armedSave = nil
        suspensionWaiters.values.flatMap { $0 }.forEach { $0.resume(throwing: error) }
        suspensionWaiters.removeAll()
        suspended?.continuation.resume(throwing: error)
    }

    struct SaveGate: Hashable, Sendable {
        private let id = UUID()
    }

    enum GateError: Error, Equatable {
        case alreadyArmed
        case alreadyFinished
        case unknownGate
        case wrongGate
        case overlappingSaves
    }

    enum Failure: Error {
        case simulated
    }
}
