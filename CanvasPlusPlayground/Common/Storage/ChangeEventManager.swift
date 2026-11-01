//
//  ChangeEventManager.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 10/31/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class ChangeEventManager {
    private(set) var isLoaded = false
    private(set) var recoveryReason: ChangeStoreLoadResult.RecoveryReason?

    private var envelope = ChangeStoreEnvelope()

    @ObservationIgnored private let store: any ChangeEventStore
    @ObservationIgnored private let clock: @Sendable () -> Date
    @ObservationIgnored private var transactionTail: Task<Void, Never>?

    /// Creates a manager with injectable persistence and time.
    /// - Parameter store: Storage used to load and commit complete envelopes.
    /// - Parameter clock: Time assigned to newly detected changes.
    init(
        store: any ChangeEventStore = JSONChangeEventStore(),
        clock: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.store = store
        self.clock = clock
    }

    /// Loads committed state once. Corrupt state is quarantined before the manager accepts mutations.
    func load() async throws {
        try await serialized {
            guard !self.isLoaded else { return }

            var restored = ChangeStoreEnvelope()
            var reason: ChangeStoreLoadResult.RecoveryReason?
            switch try await self.store.load() {
            case .loaded(let saved):
                do {
                    try self.validate(saved)
                    restored = saved
                } catch ManagerError.invalidState {
                    reason = .corrupt
                }
            case .empty(let emptyReason):
                reason = emptyReason
            }

            if reason == .corrupt {
                let quarantined = try await self.store.quarantine(timestamp: self.clock())
                LoggerService.main.error(
                    "Change indicators recovered from corrupt state; moved to \(quarantined?.path(percentEncoded: false) ?? "nothing")"
                )
            } else if let reason {
                LoggerService.main.info("Change indicators started empty: \(String(describing: reason), privacy: .public)")
            }

            self.envelope = restored
            self.recoveryReason = reason
            self.isLoaded = true
        }
    }

    /// Commits snapshots and coalesced changes together before publishing them.
    /// - Parameter observation: Authoritative snapshots and field changes from one observation.
    func apply(_ observation: ChangeObservationResult) async throws {
        try await serialized {
            try self.requireLoaded()
            guard !observation.snapshots.isEmpty || !observation.changes.isEmpty else { return }

            let snapshotKeys = observation.snapshots.map(\.itemKey)
            let changeKeys = observation.changes.map {
                RecordKey(itemKey: $0.itemKey, field: $0.field)
            }
            guard Set(snapshotKeys).count == snapshotKeys.count,
                  Set(changeKeys).count == changeKeys.count else {
                throw ManagerError.invalidState
            }

            var next = self.envelope
            let revision = self.nextRevision()
            let timestamp = self.clock()

            for snapshot in observation.snapshots {
                let index = self.accountIndex(snapshot.itemKey.account, in: &next)
                self.merge(snapshot, into: &next.accounts[index], revision: revision, timestamp: timestamp)
            }

            let changes = observation.changes.sorted { $0.field == .itemAdded && $1.field != .itemAdded }
            for change in changes {
                let index = self.accountIndex(change.itemKey.account, in: &next)
                guard let snapshot = next.accounts[index].snapshots.first(where: { $0.itemKey == change.itemKey }),
                      change.field == .itemAdded || snapshot.values[change.field] == change.newValue else {
                    throw ManagerError.invalidState
                }

                let oldAccount = self.envelope.accounts.first { $0.account == change.itemKey.account }
                let previous = oldAccount?.snapshots.first { $0.itemKey == change.itemKey }?.values[change.field]
                if change.field != .itemAdded, previous == change.newValue {
                    continue
                }

                self.coalesce(change, in: &next.accounts[index], revision: revision, timestamp: timestamp)
            }

            guard next != self.envelope else { return }
            next.commitRevision = revision
            try self.validate(next)
            try await self.store.save(next)
            self.envelope = next
        }
    }

    /// Captures the unseen records and acknowledgement boundary for an item visit.
    /// - Parameter itemKey: Item whose changes are being presented.
    /// - Returns: Records and the store generation and revision at capture time.
    func captureChanges(for itemKey: ChangeItemKey) throws -> CapturedChanges {
        try requireLoaded()
        return CapturedChanges(
            itemKey: itemKey,
            records: records(for: itemKey),
            resetGeneration: envelope.resetGeneration,
            throughRevision: envelope.commitRevision
        )
    }

    /// Removes captured item changes while preserving records from newer revisions.
    /// - Parameter capture: Visit boundary returned by captureChanges.
    func acknowledge(_ capture: CapturedChanges) async throws {
        try await serialized {
            try self.requireLoaded()
            guard capture.resetGeneration == self.envelope.resetGeneration else { return }
            guard capture.throughRevision <= self.envelope.commitRevision else { throw ManagerError.invalidState }

            var next = self.envelope
            guard let index = next.accounts.firstIndex(where: { $0.account == capture.itemKey.account }) else { return }

            next.accounts[index].records.removeAll {
                $0.itemKey == capture.itemKey && $0.revision <= capture.throughRevision
            }
            guard next != self.envelope else { return }

            next.commitRevision = self.nextRevision()
            try self.validate(next)
            try await self.store.save(next)
            self.envelope = next
        }
    }

    /// Returns unseen records for one item.
    /// - Parameter itemKey: Fully scoped item identity.
    /// - Returns: Records ordered by latest detection, then stable identity.
    func records(for itemKey: ChangeItemKey) -> [ChangeRecord] {
        records(for: itemKey.account).filter { $0.itemKey == itemKey }
    }

    /// Returns unseen records for a course within one account.
    /// - Parameter courseID: Course to query.
    /// - Parameter account: Account owning the course.
    /// - Returns: Records ordered by latest detection, then stable identity.
    func records(in courseID: String, account: AccountKey) -> [ChangeRecord] {
        records(for: account).filter { $0.itemKey.courseID == courseID }
    }

    /// Returns unseen records across one account.
    /// - Parameter account: Account to query.
    /// - Returns: Records ordered by latest detection, then stable identity.
    func records(for account: AccountKey) -> [ChangeRecord] {
        let records = envelope.accounts.first { $0.account == account }?.records ?? []

        return records.sorted {
            if $0.lastDetectedAt != $1.lastDetectedAt {
                return $0.lastDetectedAt > $1.lastDetectedAt
            }
            let lhs = [$0.itemKey.courseID, $0.itemKey.itemType.rawValue, $0.itemKey.itemID, $0.field.rawValue]
            let rhs = [$1.itemKey.courseID, $1.itemKey.itemType.rawValue, $1.itemKey.itemID, $1.field.rawValue]
            return lhs.lexicographicallyPrecedes(rhs)
        }
    }

    /// Counts distinct unseen items in a course.
    /// - Parameter courseID: Course to query.
    /// - Parameter account: Account owning the course.
    /// - Returns: Item count, regardless of how many fields changed.
    func unseenItemCount(in courseID: String, account: AccountKey) -> Int {
        Set(records(in: courseID, account: account).map(\.itemKey)).count
    }

    private func serialized(_ operation: @escaping @MainActor () async throws -> Void) async throws {
        let previous = transactionTail
        let task = Task { @MainActor in
            await previous?.value
            try await operation()
        }
        transactionTail = Task { @MainActor in
            _ = await task.result
        }
        try await task.value
    }

    private func requireLoaded() throws {
        guard isLoaded else { throw ManagerError.notLoaded }
    }

    private func nextRevision() -> UInt64 {
        envelope.commitRevision + 1
    }

    private func accountIndex(_ account: AccountKey, in next: inout ChangeStoreEnvelope) -> Int {
        if let index = next.accounts.firstIndex(where: { $0.account == account }) { return index }
        next.accounts.append(.init(account: account))
        return next.accounts.count - 1
    }

    private func merge(
        _ snapshot: ChangeSnapshot,
        into account: inout ChangeStoreEnvelope.AccountState,
        revision: UInt64,
        timestamp: Date
    ) {
        guard let index = account.snapshots.firstIndex(where: { $0.itemKey == snapshot.itemKey }) else {
            account.snapshots.append(snapshot)
            return
        }

        let old = account.snapshots[index]
        let values = old.values.merging(snapshot.values) { _, latest in latest }
        let merged = ChangeSnapshot(itemKey: snapshot.itemKey, displayTitle: snapshot.displayTitle, values: values)
        guard merged != old else { return }
        account.snapshots[index] = merged

        if let marker = account.records.firstIndex(where: { $0.itemKey == snapshot.itemKey && $0.field == .itemAdded }) {
            let record = account.records[marker]
            account.records[marker] = ChangeRecord(
                itemKey: record.itemKey,
                field: record.field,
                oldValue: record.oldValue,
                newValue: record.newValue,
                firstDetectedAt: record.firstDetectedAt,
                lastDetectedAt: max(timestamp, record.lastDetectedAt),
                revision: revision
            )
        }
    }

    private func coalesce(
        _ change: ChangeObservationResult.FieldChange,
        in account: inout ChangeStoreEnvelope.AccountState,
        revision: UInt64,
        timestamp: Date
    ) {
        guard change.oldValue != change.newValue else { return }

        if change.field == .itemAdded {
            account.records.removeAll { $0.itemKey == change.itemKey && $0.field != .itemAdded }
        } else if account.records.contains(where: { $0.itemKey == change.itemKey && $0.field == .itemAdded }) {
            return
        }

        let existing = account.records.firstIndex { $0.itemKey == change.itemKey && $0.field == change.field }
        let previous = existing.map { account.records[$0] }
        guard previous?.newValue != change.newValue else { return }

        let oldValue = previous?.oldValue ?? change.oldValue
        if oldValue == change.newValue {
            if let existing { account.records.remove(at: existing) }
            return
        }

        let record = ChangeRecord(
            itemKey: change.itemKey,
            field: change.field,
            oldValue: oldValue,
            newValue: change.newValue,
            firstDetectedAt: previous?.firstDetectedAt ?? timestamp,
            lastDetectedAt: max(timestamp, previous?.lastDetectedAt ?? timestamp),
            revision: revision
        )
        if let existing {
            account.records[existing] = record
        } else {
            account.records.append(record)
        }
    }

    struct CapturedChanges: Equatable, Sendable {
        let itemKey: ChangeItemKey
        let records: [ChangeRecord]
        let resetGeneration: UUID
        let throughRevision: UInt64
    }

    enum ManagerError: Error {
        case notLoaded
        case invalidState
    }

    private struct RecordKey: Hashable {
        let itemKey: ChangeItemKey
        let field: ChangeField
    }
}

private extension ChangeEventManager {
    func validate(_ state: ChangeStoreEnvelope) throws {
        guard state.formatVersion == ChangeStoreEnvelope.currentFormatVersion else {
            throw ChangeStoreError.unsupportedFormat(state.formatVersion)
        }
        guard Set(state.accounts.map(\.account)).count == state.accounts.count else { throw ManagerError.invalidState }

        for account in state.accounts {
            try validate(account, throughRevision: state.commitRevision)
        }
    }

    func validate(
        _ account: ChangeStoreEnvelope.AccountState,
        throughRevision revision: UInt64
    ) throws {
        let snapshots = account.snapshots
        guard Set(snapshots.map(\.itemKey)).count == snapshots.count else { throw ManagerError.invalidState }
        let snapshotLookup = Dictionary(uniqueKeysWithValues: snapshots.map {
            ($0.itemKey, $0)
        })
        for snapshot in snapshots {
            guard snapshot.itemKey.account == account.account,
                  !snapshot.itemKey.courseID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !snapshot.itemKey.itemID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  snapshot.values.allSatisfy({ $0.key != .itemAdded && self.isValid($0.value, for: $0.key) }) else {
                throw ManagerError.invalidState
            }
        }

        let keys = account.records.map {
            RecordKey(itemKey: $0.itemKey, field: $0.field)
        }
        let addedItems = Set(account.records.filter { $0.field == .itemAdded }.map(\.itemKey))
        guard Set(keys).count == keys.count else { throw ManagerError.invalidState }

        for record in account.records {
            guard record.itemKey.account == account.account,
                  let snapshot = snapshotLookup[record.itemKey],
                  record.revision > 0 && record.revision <= revision,
                  record.firstDetectedAt.timeIntervalSinceReferenceDate.isFinite,
                  record.lastDetectedAt.timeIntervalSinceReferenceDate.isFinite,
                  record.firstDetectedAt <= record.lastDetectedAt,
                  record.oldValue != record.newValue,
                  isValid(record.oldValue, for: record.field),
                  isValid(record.newValue, for: record.field) else {
                throw ManagerError.invalidState
            }

            if record.field == .itemAdded {
                guard record.oldValue == .boolean(false),
                      record.newValue == .boolean(true) else {
                    throw ManagerError.invalidState
                }
            } else {
                guard !addedItems.contains(record.itemKey),
                      snapshot.values[record.field] == record.newValue else {
                    throw ManagerError.invalidState
                }
            }
        }
    }

    func isValid(_ value: ChangeValue, for field: ChangeField) -> Bool {
        switch (field, value) {
        case (.itemAdded, .boolean), (.name, .text), (.descriptionHash, .descriptionHash):
            return true
        case (.dueAt, .null), (.lockAt, .null), (.unlockAt, .null), (.pointsPossible, .null),
             (.descriptionHash, .null), (.grade, .null):
            return true
        case (.dueAt, .date(let date)), (.lockAt, .date(let date)), (.unlockAt, .date(let date)):
            return date.timeIntervalSinceReferenceDate.isFinite
        case (.pointsPossible, .number(let number)):
            return number.isFinite
        case (.grade, .grade(let grade)):
            return (grade.score?.isFinite ?? true)
                && (grade.gradedAt?.timeIntervalSinceReferenceDate.isFinite ?? true)
        default:
            return false
        }
    }
}
