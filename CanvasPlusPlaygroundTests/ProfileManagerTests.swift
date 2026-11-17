@testable import CanvasPlusPlayground
import Foundation
import Testing

@MainActor
struct ProfileManagerTests {
    @Test func verifiesNetworkUserWithDefaultHost() async throws {
        let fixture = IdentityFixture()
        let manager = fixture.makeManager()
        let refresh = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(0).started.wait()
        fixture.request(0).respond(.success(User(from: .sample1)))
        await refresh.value

        let identity = try #require(manager.trackingIdentity)
        let account = try AccountKey(rawHost: CanvasService.canvasWebURL, rawUserID: "1001")
        #expect(identity.account == account)
        #expect(identity.account.host == "gatech.instructure.com")
        #expect(identity.credentialGeneration == fixture.tracker.credentialGeneration)
        #expect(manager.isCurrent(identity))
    }

    @Test func cachedUserCannotEstablishIdentityWhenNetworkFails() async {
        let fixture = IdentityFixture()
        let manager = fixture.makeManager()
        let refresh = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(0).started.wait()
        fixture.request(0).receiveCache?(User(from: .sample2))
        #expect(manager.currentUser?.id == "1002")
        #expect(manager.trackingIdentity == nil)

        fixture.request(0).respond(.failure(IdentityFailure.simulated))
        await refresh.value
        #expect(manager.currentUser?.id == "1002")
        #expect(manager.trackingIdentity == nil)
    }

    @Test func lateSameGenerationResponseAfterTimeoutUpdatesDisplayOnly() async {
        let fixture = IdentityFixture()
        let manager = fixture.makeManager()
        let refresh = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(0).started.wait()
        await fixture.timer(0).started.wait()
        fixture.timer(0).release.open()
        await refresh.value
        #expect(manager.trackingIdentity == nil)
        #expect(fixture.durations == [ProfileManager.identityTimeout])

        fixture.request(0).respond(.success(User(from: .sample1)))
        await fixture.request(0).returned.wait()
        #expect(manager.currentUser?.id == "1001")
        #expect(manager.trackingIdentity == nil)
    }

    @Test func expiredDeadlineRejectsIdentityWhenTimeoutTaskHasNotFired() async {
        let fixture = IdentityFixture()
        let manager = fixture.makeManager()
        let refresh = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(0).started.wait()
        await fixture.timer(0).started.wait()

        // Expire the deadline while the timeout task remains suspended.
        fixture.now = fixture.now.advanced(by: ProfileManager.identityTimeout)
        fixture.request(0).respond(.success(User(from: .sample1)))
        await refresh.value

        #expect(manager.currentUser?.id == "1001")
        #expect(manager.trackingIdentity == nil)
    }

    @Test func retryAfterTimeoutSupersedesLateResponse() async {
        let fixture = IdentityFixture()
        let manager = fixture.makeManager()
        let first = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(0).started.wait()
        await fixture.timer(0).started.wait()
        fixture.timer(0).release.open()
        await first.value

        let second = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(1).started.wait()
        fixture.request(0).respond(.success(User(from: .sample1)))
        await fixture.request(0).returned.wait()
        // Cancellation documents why removing the request-ID check alone is equivalent under today's lifecycle.
        #expect(fixture.request(0).wasCancelledAtReturn == true)
        #expect(manager.currentUser == nil)
        #expect(manager.trackingIdentity == nil)

        fixture.request(1).respond(.success(User(from: .sample2)))
        await second.value
        #expect(manager.currentUser?.id == "1002")
        #expect(manager.trackingIdentity?.account.userID == "1002")
        #expect(fixture.requestCount == 2)
    }

    @Test func credentialChangeSupersedesAnActiveRefresh() async throws {
        let fixture = IdentityFixture()
        let manager = fixture.makeManager()
        let first = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(0).started.wait()
        try fixture.tracker.replaceToken("replacement")

        let second = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(1).started.wait()
        await first.value
        fixture.request(1).respond(.success(User(from: .sample2)))
        await second.value
        fixture.request(0).respond(.success(User(from: .sample1)))
        await fixture.request(0).returned.wait()
        #expect(manager.currentUser?.id == "1002")
        #expect(manager.trackingIdentity?.account.userID == "1002")
    }

    @Test func rejectsTokenReplacementMidFlight() async throws {
        let fixture = IdentityFixture()
        let manager = fixture.makeManager()
        let refresh = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(0).started.wait()
        let displayedUser = User(from: .sample2)
        fixture.request(0).receiveCache?(displayedUser)
        try fixture.tracker.replaceToken("replacement")
        fixture.request(0).respond(.success(User(from: .sample1)))
        await refresh.value
        #expect(manager.currentUser === displayedUser)
        #expect(manager.trackingIdentity == nil)
    }

    @Test func cancellationResumesCallerAndRejectsLateResponse() async {
        let fixture = IdentityFixture()
        let manager = fixture.makeManager()
        let refresh = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(0).started.wait()
        refresh.cancel()
        await refresh.value

        fixture.request(0).respond(.success(User(from: .sample1)))
        await fixture.request(0).returned.wait()
        #expect(manager.currentUser == nil)
        #expect(manager.trackingIdentity == nil)
    }

    @Test func emptyResponseDoesNotEstablishIdentity() async {
        let fixture = IdentityFixture()
        let manager = fixture.makeManager()
        let refresh = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(0).started.wait()
        fixture.request(0).respond(.success(nil))
        await refresh.value
        #expect(manager.currentUser == nil)
        #expect(manager.trackingIdentity == nil)
    }

    @Test(arguments: [("https://127.0.0.1", "1001"), (CanvasService.canvasWebURL, " \n")])
    func accountValidationFailureLeavesTrackingUnavailable(host: String, userID: String) async {
        let fixture = IdentityFixture()
        let manager = ProfileManager(
            host: host,
            isSandbox: false,
            loadCurrentUser: fixture.loadUser,
            readCredentialGeneration: { fixture.tracker.credentialGeneration },
            waitForIdentityTimeout: fixture.waitForTimeout
        )
        let refresh = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(0).started.wait()
        let user = User(from: .sample1)
        user.id = userID
        fixture.request(0).respond(.success(user))
        await refresh.value
        #expect(manager.currentUser === user)
        #expect(manager.trackingIdentity == nil)
    }

    @Test func sandboxSkipsIdentityLoading() async {
        let fixture = IdentityFixture()
        let manager = fixture.makeManager(isSandbox: true)
        await manager.refreshTrackingIdentity()
        #expect(fixture.requestCount == 0)
        #expect(fixture.durations.isEmpty)
        #expect(manager.trackingIdentity == nil)
    }

    @Test func nextLoadRetriesAfterFailure() async {
        let fixture = IdentityFixture()
        let manager = fixture.makeManager()
        let first = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(0).started.wait()
        fixture.request(0).respond(.failure(IdentityFailure.simulated))
        await first.value
        #expect(manager.trackingIdentity == nil)

        let second = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(1).started.wait()
        fixture.request(1).respond(.success(User(from: .sample1)))
        await second.value
        #expect(fixture.requestCount == 2)
        #expect(manager.trackingIdentity?.account.userID == "1001")
    }

    @Test func coalescedCallersCanCancelIndependently() async {
        let fixture = IdentityFixture()
        let manager = fixture.makeManager()
        let first = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(0).started.wait()
        let secondStarted = IdentitySignal()
        let second = Task {
            secondStarted.open()
            await manager.refreshTrackingIdentity()
        }
        await secondStarted.wait()
        first.cancel()
        await first.value
        fixture.request(0).respond(.success(User(from: .sample1)))
        await second.value
        #expect(fixture.requestCount == 1)
        #expect(manager.trackingIdentity?.account.userID == "1001")
    }

    @Test func replacingCredentialsInvalidatesACapturedIdentity() async throws {
        let fixture = IdentityFixture()
        let manager = fixture.makeManager()
        let refresh = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(0).started.wait()
        fixture.request(0).respond(.success(User(from: .sample1)))
        await refresh.value
        let identity = try #require(manager.trackingIdentity)

        try fixture.tracker.replaceToken("replacement")
        #expect(manager.trackingIdentity == nil)
        #expect(!manager.isCurrent(identity))
    }

    // Pins today's identity-retention policy; PR 3 may choose to retain same-generation identity during refresh.
    @Test func currentPolicyClearsIdentityForANewSameGenerationAttempt() async {
        let fixture = IdentityFixture()
        let manager = fixture.makeManager()
        let first = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(0).started.wait()
        fixture.request(0).respond(.success(User(from: .sample1)))
        await first.value
        #expect(manager.trackingIdentity != nil)

        let second = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(1).started.wait()
        #expect(manager.trackingIdentity == nil)
        fixture.request(1).respond(.failure(IdentityFailure.simulated))
        await second.value
        #expect(manager.trackingIdentity == nil)
    }

    @Test func legacyMigrationInvalidatesTheGenerationCapturedBeforeLoading() async throws {
        let suiteName = "ProfileManagerTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("legacy", forKey: StorageKeys.accessTokenKey)
        let fixture = IdentityFixture()
        let manager = ProfileManager(
            isSandbox: false,
            loadCurrentUser: { receiveCache in
                _ = StorageKeys.readAccessToken(
                    from: defaults,
                    read: { "legacy" },
                    replace: { token in
                        do { try fixture.tracker.replaceToken(token) } catch { Issue.record(error) }
                    }
                )
                return try await fixture.loadUser(receiveCache)
            },
            readCredentialGeneration: { fixture.tracker.credentialGeneration },
            waitForIdentityTimeout: fixture.waitForTimeout
        )
        let first = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(0).started.wait()
        fixture.request(0).respond(.success(User(from: .sample1)))
        await first.value
        #expect(manager.trackingIdentity == nil)

        let second = Task { await manager.refreshTrackingIdentity() }
        await fixture.request(1).started.wait()
        fixture.request(1).respond(.success(User(from: .sample1)))
        await second.value
        #expect(manager.trackingIdentity?.account.userID == "1001")
    }
}

private enum IdentityFailure: Error {
    case simulated
}

@MainActor
private final class IdentitySignal {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        let pending = waiters
        waiters.removeAll()
        pending.forEach { $0.resume() }
    }
}

@MainActor
private final class IdentityRequest {
    let started = IdentitySignal()
    let release = IdentitySignal()
    let returned = IdentitySignal()
    var receiveCache: (@MainActor (User?) -> Void)?
    var response: Result<User?, Error> = .success(nil)
    var wasCancelledAtReturn: Bool?

    func respond(_ result: Result<User?, Error>) {
        response = result
        release.open()
    }
}

@MainActor
private final class IdentityTimer {
    let started = IdentitySignal()
    let release = IdentitySignal()
}

@MainActor
private final class IdentityFixture {
    let tracker = CredentialGenerationTracker(persist: { _ in })
    var now = ContinuousClock.now
    private(set) var requestCount = 0
    private(set) var durations: [Duration] = []
    private var requests: [Int: IdentityRequest] = [:]
    private var timers: [Int: IdentityTimer] = [:]

    func makeManager(isSandbox: Bool = false) -> ProfileManager {
        ProfileManager(
            isSandbox: isSandbox,
            loadCurrentUser: loadUser,
            readCredentialGeneration: { self.tracker.credentialGeneration },
            waitForIdentityTimeout: waitForTimeout,
            identityNow: { self.now }
        )
    }

    func request(_ index: Int) -> IdentityRequest {
        if let request = requests[index] { return request }
        let request = IdentityRequest()
        requests[index] = request
        return request
    }

    func timer(_ index: Int) -> IdentityTimer {
        if let timer = timers[index] { return timer }
        let timer = IdentityTimer()
        timers[index] = timer
        return timer
    }

    func loadUser(_ receiveCache: @escaping @MainActor (User?) -> Void) async throws -> User? {
        let request = request(requestCount)
        requestCount += 1
        request.receiveCache = receiveCache
        request.started.open()
        // Ignore cancellation so the manager must reject late responses itself.
        await request.release.wait()
        request.wasCancelledAtReturn = Task.isCancelled
        defer {
            Task { @MainActor in request.returned.open() }
        }
        return try request.response.get()
    }

    func waitForTimeout(_ duration: Duration) async throws {
        let timer = timer(durations.count)
        durations.append(duration)
        timer.started.open()
        try await withTaskCancellationHandler {
            await timer.release.wait()
            try Task.checkCancellation()
        } onCancel: {
            Task { @MainActor in timer.release.open() }
        }
    }
}
