//
//  ProfileManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/18/24.
//

import SwiftUI

@Observable
@MainActor
class ProfileManager {
    typealias CurrentUserLoader = @MainActor (
        @escaping @MainActor (User?) -> Void
    ) async throws -> User?

    static let identityTimeout: Duration = .seconds(3)

    private(set) var currentUser: User?
    private(set) var currentProfile: Profile?

    private var verifiedIdentity: TrackingIdentity?

    @ObservationIgnored private let host: String
    @ObservationIgnored private let isSandbox: Bool
    @ObservationIgnored private let loadCurrentUser: CurrentUserLoader
    @ObservationIgnored private let readCredentialGeneration: @MainActor () -> UUID?
    @ObservationIgnored private let waitForIdentityTimeout: @MainActor (Duration) async throws -> Void
    @ObservationIgnored private let identityNow: @MainActor () -> ContinuousClock.Instant
    @ObservationIgnored private var pendingRefresh: IdentityRefresh?

    /// Returns the verified identity while its credential generation remains current.
    var trackingIdentity: TrackingIdentity? {
        guard let verifiedIdentity,
              let currentGeneration = readCredentialGeneration(),
              currentGeneration == verifiedIdentity.credentialGeneration else { return nil }
        return verifiedIdentity
    }

    /// Creates a profile manager with injectable identity loading and timeout behavior.
    /// - Parameters:
    ///   - host: Canvas host used to scope the verified account.
    ///   - isSandbox: Whether real account tracking is disabled for sandbox data.
    ///   - loadCurrentUser: Returns a network-fresh user and optionally delivers cached display data.
    ///   - readCredentialGeneration: Returns the settled credential generation, or nil during replacement.
    ///   - waitForIdentityTimeout: Suspends for the supplied timeout, throwing when cancelled.
    ///   - identityNow: Current monotonic time used for identity deadlines.
    init(
        host: String = CanvasService.canvasWebURL,
        isSandbox: Bool = AppEnvironment.isSandbox,
        loadCurrentUser: @escaping CurrentUserLoader = { receiveCache in
            // Superseded responses can merge into cached Users in place; identity requires a network result and matching generation.
            let users: [User] = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getUser(),
                onCacheReceive: { receiveCache($0?.first) }
            )
            return users.first
        },
        readCredentialGeneration: @escaping @MainActor () -> UUID? = {
            StorageKeys.credentialGeneration
        },
        waitForIdentityTimeout: @escaping @MainActor (Duration) async throws -> Void = { duration in
            try await Task.sleep(for: duration)
        },
        identityNow: @escaping @MainActor () -> ContinuousClock.Instant = { ContinuousClock.now }
    ) {
        self.host = host
        self.isSandbox = isSandbox
        self.loadCurrentUser = loadCurrentUser
        self.readCredentialGeneration = readCredentialGeneration
        self.waitForIdentityTimeout = waitForIdentityTimeout
        self.identityNow = identityNow
    }

    /// Checks whether a captured tracking identity is still verified for the current credentials.
    /// - Parameter identity: Identity captured before starting a sync.
    /// - Returns: Whether the identity remains eligible for tracking.
    func isCurrent(_ identity: TrackingIdentity) -> Bool {
        trackingIdentity == identity
    }

    // MARK: - Methods

    /// Refreshes identity and profile display data concurrently.
    func getCurrentUserAndProfile() async {
        async let identity: Void = refreshTrackingIdentity()
        async let profile: Void = getCurrentProfile()
        await (_, _) = (identity, profile)
    }

    /// Awaits a fresh identity until its deadline, sharing an active attempt for the same credentials.
    func refreshTrackingIdentity() async {
        guard !isSandbox else {
            verifiedIdentity = nil
            if let pendingRefresh { finishRefresh(pendingRefresh.id) }
            return
        }
        let capturedGeneration = readCredentialGeneration()
        guard let capturedGeneration else {
            verifiedIdentity = nil
            if let pendingRefresh { finishRefresh(pendingRefresh.id) }
            return
        }
        let callerID = UUID()

        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                guard !Task.isCancelled else {
                    continuation.resume()
                    return
                }
                let refresh = prepareRefresh(generation: capturedGeneration)
                refresh.waiters[callerID] = continuation
                if refresh.request == nil {
                    refresh.request = Task { await fetchTrackingUser(refresh) }
                    refresh.timeout = Task {
                        do {
                            try await waitForIdentityTimeout(Self.identityTimeout)
                        } catch {
                            return
                        }
                        expireIdentityWait(refresh.id)
                    }
                }
            }
        } onCancel: {
            Task { @MainActor in self.cancelWaiter(callerID) }
        }
    }

    /// Refreshes profile display data separately from the identity deadline.
    func getCurrentProfile() async {
        do {
            let profiles: [Profile] = try await CanvasService.shared.loadAndSync(CanvasRequest.getUserProfile(), onCacheReceive: { profiles in
                currentProfile = profiles?.first
            })

            currentProfile = profiles.first
        } catch {
            LoggerService.main.error("Error fetching current user profile: \(error)")
        }

        LoggerService.main.debug("Current user: \(self.currentUser?.name ?? "")")
        LoggerService.main.debug("Current user profile: \(self.currentProfile?.primaryEmail ?? "")")
    }

    func getProfile(for id: User.ID) async -> Profile? {
        do {
            return try await CanvasService.shared.loadAndSync(CanvasRequest.getUserProfile(userId: id))[0] as Profile
        } catch {
            LoggerService.main.error("Error fetching user profile: \(error)")
        }

        return nil
    }

    private func prepareRefresh(generation: UUID) -> IdentityRefresh {
        if let pendingRefresh, pendingRefresh.generation == generation,
           pendingRefresh.acceptsIdentity, identityNow() < pendingRefresh.deadline {
            return pendingRefresh
        }
        if let pendingRefresh { finishRefresh(pendingRefresh.id) }
        verifiedIdentity = nil
        let refresh = IdentityRefresh(generation: generation, deadline: identityNow().advanced(by: Self.identityTimeout))
        pendingRefresh = refresh
        return refresh
    }

    private func fetchTrackingUser(_ refresh: IdentityRefresh) async {
        defer { finishRefresh(refresh.id) }
        do {
            let user = try await loadCurrentUser { cachedUser in
                guard self.matchesRefresh(refresh), !Task.isCancelled else { return }
                self.currentUser = cachedUser
            }
            guard matchesRefresh(refresh), !Task.isCancelled else { return }
            guard let user else {
                LoggerService.main.error("Current user response contained no user.")
                return
            }
            // A late response for the active refresh and generation may update display data only.
            currentUser = user
            // The deadline check backs up a timeout task that runs late.
            guard refresh.acceptsIdentity, identityNow() < refresh.deadline else { return }
            let account = try AccountKey(rawHost: host, rawUserID: user.id)
            verifiedIdentity = TrackingIdentity(account: account, credentialGeneration: refresh.generation)
        } catch {
            guard matchesRefresh(refresh), !Task.isCancelled else { return }
            LoggerService.main.error("Error fetching current user: \(error)")
        }
    }

    private func matchesRefresh(_ refresh: IdentityRefresh) -> Bool {
        // Defense in depth: superseding also cancels the request task.
        guard pendingRefresh?.id == refresh.id,
              let currentGeneration = readCredentialGeneration() else { return false }
        return currentGeneration == refresh.generation
    }

    private func expireIdentityWait(_ id: UUID) {
        guard let pendingRefresh, pendingRefresh.id == id else { return }
        pendingRefresh.acceptsIdentity = false
        let waiters = pendingRefresh.waiters.values
        pendingRefresh.waiters.removeAll()
        waiters.forEach { $0.resume() }
    }

    private func cancelWaiter(_ callerID: UUID) {
        guard let pendingRefresh,
              let waiter = pendingRefresh.waiters.removeValue(forKey: callerID) else { return }
        waiter.resume()
        if pendingRefresh.waiters.isEmpty { finishRefresh(pendingRefresh.id) }
    }

    private func finishRefresh(_ id: UUID) {
        guard let pendingRefresh, pendingRefresh.id == id else { return }
        self.pendingRefresh = nil
        pendingRefresh.request?.cancel()
        pendingRefresh.timeout?.cancel()
        pendingRefresh.waiters.values.forEach { $0.resume() }
        pendingRefresh.waiters.removeAll()
    }

    /// Sets user and profile for sandbox mode. Only used when AppEnvironment.isSandbox is true.
    func setSandboxUserAndProfile(user: User, profile: Profile) {
        verifiedIdentity = nil
        if let pendingRefresh { finishRefresh(pendingRefresh.id) }
        currentUser = user
        currentProfile = profile
    }

    @MainActor
    private final class IdentityRefresh {
        let id = UUID()
        let generation: UUID
        let deadline: ContinuousClock.Instant
        var acceptsIdentity = true
        var waiters: [UUID: CheckedContinuation<Void, Never>] = [:]
        var request: Task<Void, Never>?
        var timeout: Task<Void, Never>?

        init(generation: UUID, deadline: ContinuousClock.Instant) {
            self.generation = generation
            self.deadline = deadline
        }
    }
}
