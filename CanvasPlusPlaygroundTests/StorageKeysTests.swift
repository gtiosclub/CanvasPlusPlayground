@testable import CanvasPlusPlayground
import Foundation
import os
import Testing

struct StorageKeysTests {
    @Test(arguments: ["replacement", ""])
    func replacementChangesGeneration(token: String) throws {
        let tokens = OSAllocatedUnfairLock(initialState: [String]())
        let tracker = CredentialGenerationTracker { token in
            tokens.withLock { $0.append(token) }
        }
        let before = try #require(tracker.credentialGeneration)
        try tracker.replaceToken(token)
        let after = try #require(tracker.credentialGeneration)
        #expect(before != after)
        #expect(tokens.withLock { $0 } == [token])
    }

    @Test func persistenceFailureStillChangesGeneration() throws {
        let tracker = CredentialGenerationTracker { _ in throw PersistenceFailure.simulated }
        let before = try #require(tracker.credentialGeneration)
        #expect(throws: PersistenceFailure.simulated) {
            try tracker.replaceToken("replacement")
        }
        let after = try #require(tracker.credentialGeneration)
        #expect(before != after)
    }

    @Test func readersSeeNilDuringPersistenceAndANewGenerationAfterward() async throws {
        let entered = DispatchSemaphore(value: 0)
        let release = DispatchSemaphore(value: 0)
        let tokens = OSAllocatedUnfairLock(initialState: [String]())
        let tracker = CredentialGenerationTracker { token in
            entered.signal()
            release.wait()
            tokens.withLock { $0.append(token) }
        }
        let before = try #require(tracker.credentialGeneration)
        let replacement = Task { try await replaceOnWorker("replacement", using: tracker) }
        defer { release.signal() }
        let enteredStatus = await waitForSignal(entered)
        try #require(enteredStatus == .success)
        #expect(tracker.credentialGeneration == nil)
        #expect(tokens.withLock { $0.isEmpty })

        release.signal()
        try await replacement.value
        let after = try #require(tracker.credentialGeneration)
        #expect(after != before)
        #expect(tokens.withLock { $0 } == ["replacement"])
    }

    @Test func concurrentReplacementsPreserveWriterOrder() async throws {
        let firstEntered = DispatchSemaphore(value: 0)
        let releaseFirst = DispatchSemaphore(value: 0)
        let secondStarted = DispatchSemaphore(value: 0)
        let secondEntered = DispatchSemaphore(value: 0)
        let releaseSecond = DispatchSemaphore(value: 0)
        let tokens = OSAllocatedUnfairLock(initialState: [String]())
        let tracker = CredentialGenerationTracker { token in
            if token == "first" {
                firstEntered.signal()
                releaseFirst.wait()
            } else {
                secondEntered.signal()
                releaseSecond.wait()
            }
            tokens.withLock { $0.append(token) }
        }
        let before = try #require(tracker.credentialGeneration)
        let first = Task { try await replaceOnWorker("first", using: tracker) }
        defer {
            releaseFirst.signal()
            releaseSecond.signal()
        }
        let firstStatus = await waitForSignal(firstEntered)
        try #require(firstStatus == .success)
        let second = Task {
            try await replaceOnWorker("second", using: tracker, started: secondStarted)
        }
        let secondStartedStatus = await waitForSignal(secondStarted)
        try #require(secondStartedStatus == .success)
        let blockedStatus = await waitForSignal(secondEntered, timeout: .milliseconds(100))
        #expect(blockedStatus == .timedOut)
        #expect(tracker.credentialGeneration == nil)
        releaseFirst.signal()
        let secondEnteredStatus = await waitForSignal(secondEntered)
        try #require(secondEnteredStatus == .success)
        try await first.value
        #expect(tracker.credentialGeneration == nil)
        #expect(tokens.withLock { $0 } == ["first"])

        releaseSecond.signal()
        try await second.value
        let after = try #require(tracker.credentialGeneration)
        #expect(after != before)
        #expect(tokens.withLock { $0 } == ["first", "second"])
    }

    @Test func legacyMigrationRemovesReplacesThenReadsAndChangesGeneration() throws {
        let suiteName = "StorageKeysTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("legacy", forKey: StorageKeys.accessTokenKey)
        let tokens = OSAllocatedUnfairLock(initialState: [String]())
        let steps = OSAllocatedUnfairLock(initialState: [String]())
        let tracker = CredentialGenerationTracker { token in
            steps.withLock { $0.append("persist") }
            tokens.withLock { $0.append(token) }
        }
        let before = try #require(tracker.credentialGeneration)
        let token = StorageKeys.readAccessToken(
            from: defaults,
            read: {
                steps.withLock { $0.append("read") }
                return tokens.withLock { $0.last ?? "" }
            },
            replace: { token in
                #expect(defaults.string(forKey: StorageKeys.accessTokenKey) == nil)
                steps.withLock { $0.append("replace") }
                do { try tracker.replaceToken(token) } catch { Issue.record(error) }
            }
        )
        let after = try #require(tracker.credentialGeneration)
        #expect(after != before)
        #expect(token == "legacy")
        #expect(steps.withLock { $0 } == ["replace", "persist", "read"])
        #expect(defaults.string(forKey: StorageKeys.accessTokenKey) == nil)

        _ = StorageKeys.readAccessToken(
            from: defaults,
            read: { tokens.withLock { $0.last ?? "" } },
            replace: { _ in Issue.record("Legacy token was migrated twice.") }
        )
        #expect(tracker.credentialGeneration == after)
    }

    @Test func missingLegacyTokenOnlyReadsPersistence() throws {
        let suiteName = "StorageKeysTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let token = StorageKeys.readAccessToken(
            from: defaults,
            read: { "existing" },
            replace: { _ in Issue.record("Unexpected replacement without a legacy token.") }
        )
        #expect(token == "existing")
    }

    /// Waits on a worker queue without blocking the asynchronous test executor.
    /// - Parameters:
    ///   - signal: Semaphore marking a controlled persistence step.
    ///   - timeout: Maximum time to wait for the signal.
    /// - Returns: Whether the signal arrived before the timeout.
    private func waitForSignal(
        _ signal: DispatchSemaphore,
        timeout: DispatchTimeInterval = .seconds(5)
    ) async -> DispatchTimeoutResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(returning: signal.wait(timeout: .now() + timeout))
            }
        }
    }

    /// Runs synchronous replacement on a worker queue so persistence can be gated by the test.
    /// - Parameters:
    ///   - token: Fake token to persist.
    ///   - tracker: Isolated tracker backed by fake persistence.
    ///   - started: Optional signal emitted immediately before attempting replacement.
    private func replaceOnWorker(
        _ token: String,
        using tracker: CredentialGenerationTracker,
        started: DispatchSemaphore? = nil
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global().async {
                started?.signal()
                continuation.resume(with: Result { try tracker.replaceToken(token) })
            }
        }
    }
}

private enum PersistenceFailure: Error {
    case simulated
}
