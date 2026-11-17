//
//  StorageKeys.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import Foundation
import os

enum StorageKeys {
    private static let credentialTracker = CredentialGenerationTracker(
        persist: { token in persistNewAccessToken(token) }
    )

    /// Identifies settled credentials, or is nil while replacement is in progress.
    static var credentialGeneration: UUID? {
        credentialTracker.credentialGeneration
    }

    static let accessTokenKey = "com.canvasPlus.AccessToken"
    static let installedModelsKey = "com.canvasPlus.installedModels"
    static let hasCompletedOnboardingKey = "com.canvasPlus.hasCompletedOnboarding"

    static let baseKeychainQuery = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: accessTokenKey,
        kSecAttrAccount as String: accessTokenKey
    ] as [String : Any]

    static var accessTokenValue: String {
        get {
            readAccessToken(
                from: .standard,
                read: getAccessToken,
                replace: setNewAccessToken
            )
        }

        set {
            setNewAccessToken(newValue)
        }
    }

    /// Reads the token after migrating any legacy value through the replacement path.
    /// - Parameters:
    ///   - defaults: Defaults containing a possible legacy token.
    ///   - read: Reads the persisted token.
    ///   - replace: Replaces the token and invalidates its previous generation.
    /// - Returns: The token returned by the persistence reader.
    static func readAccessToken(
        from defaults: UserDefaults,
        read: () -> String,
        replace: (String) -> Void
    ) -> String {
        // TODO: remove this block after April 10
        // For beta users that have tokens in `UserDefaults`
        if let token = defaults.string(forKey: accessTokenKey) {
            defaults.removeObject(forKey: accessTokenKey)
            replace(token)
        }
        // dont remove after this line

        return read()
    }

    static func getAccessToken() -> String {
        let query: [String: Any] = [
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ].merging(baseKeychainQuery, uniquingKeysWith: { _, _ in })

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess, let data = item as? Data, let token = String(data: data, encoding: .utf8) {
            return token
        } else {
            LoggerService.main.error("[StorageKeys] Failed to retrieve access token.")
            return ""
        }
    }

    /// Replaces the access token and invalidates previously verified tracking identities.
    /// - Parameter token: Replacement token, or an empty string to remove access.
    static func setNewAccessToken(_ token: String) {
        do {
            try credentialTracker.replaceToken(token)
        } catch {
            LoggerService.main.error("Failed to replace access token: \(error)")
        }
    }

    private static func persistNewAccessToken(_ token: String) {
        SecItemDelete(baseKeychainQuery as CFDictionary)

        guard !token.isEmpty else {
            return
        }

        guard let tokenData = token.data(using: .utf8) else {
            LoggerService.main.error("[StorageKeys] Failed to convert token to data")
            return
        }

        let addQuery: [String: Any] = [
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ].merging(baseKeychainQuery, uniquingKeysWith: { _, _ in })

        let status = SecItemAdd(addQuery as CFDictionary, nil)

        guard status == errSecSuccess else {
            LoggerService.main.error("[StorageKeys] Failed to store access token.")
            return
        }
    }

    static var needsAuthorization: Bool {
        accessTokenValue.isEmpty
    }

    static var hasCompletedOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey)
        }
    }
}

final class CredentialGenerationTracker: Sendable {
    private let writerLock = OSAllocatedUnfairLock<Void>()
    private let stateLock = OSAllocatedUnfairLock(initialState: State())
    // Persistence must not re-enter this tracker.
    private let persist: @Sendable (String) throws -> Void

    /// Identifies settled credentials, or is nil while replacement is in progress.
    var credentialGeneration: UUID? {
        stateLock.withLock { state in
            state.isReplacing ? nil : state.generation
        }
    }

    /// Creates an independent tracker backed by the supplied persistence operation.
    /// - Parameter persist: Synchronously replaces the token, throwing on failure.
    init(persist: @escaping @Sendable (String) throws -> Void) {
        self.persist = persist
    }

    /// Serializes token replacement and invalidates the previous credential generation.
    /// - Parameter token: Replacement token passed to persistence.
    /// - Throws: The persistence error, after making the new generation available.
    func replaceToken(_ token: String) throws {
        try writerLock.withLock { _ in
            stateLock.withLock { state in
                state.generation = UUID()
                state.isReplacing = true
            }
            defer {
                stateLock.withLock { state in
                    state.isReplacing = false
                }
            }
            try persist(token)
        }
    }

    private struct State: Sendable {
        var generation = UUID()
        var isReplacing = false
    }
}
