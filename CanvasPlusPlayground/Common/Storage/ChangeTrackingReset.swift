enum ChangeTrackingReset {
    enum Policy: Sendable {
        case required
        case bestEffort
    }

    /// Clears the cache only after tracking has been reset successfully.
    /// - Parameters:
    ///   - manager: The app-owned tracking manager.
    ///   - clear: Main-store operation performed after the reset succeeds.
    /// - Throws: Tracking failures and errors from `clear`.
    @MainActor
    static func clearCache(manager: ChangeEventManager, clear: () throws -> Void) async throws {
        try await resetThenClear(manager: manager, policy: .required, clear: clear)
    }

    /// Erases local storage after attempting to reset tracking, even if tracking fails.
    /// - Parameters:
    ///   - manager: The app-owned tracking manager.
    ///   - erase: Main-store operation performed after the reset attempt finishes; its errors propagate.
    /// - Throws: Errors from `erase` only.
    @MainActor
    static func recoverStorage(manager: ChangeEventManager, erase: () throws -> Void) async throws {
        try await resetThenClear(manager: manager, policy: .bestEffort, clear: erase)
    }

    /// Attempts to reset tracking before clearing the main store.
    /// - Parameters:
    ///   - manager: The app-owned tracking manager.
    ///   - policy: Whether tracking failure stops clearing or is logged before continuing.
    ///   - clear: Main-store operation performed after the tracking attempt finishes.
    /// - Throws: Tracking failures only under `.required`; errors from `clear` always propagate.
    @MainActor
    static func resetThenClear(
        manager: ChangeEventManager,
        policy: Policy,
        clear: () throws -> Void
    ) async throws {
        do {
            try await manager.load()
            try await manager.reset()
        } catch {
            switch policy {
            case .required:
                throw error
            case .bestEffort:
                LoggerService.main.error("Resetting change tracking during storage recovery failed: \(error)")
            }
        }
        try clear()
    }
}
