//
//  CloudSettings.swift
//  CanvasPlusPlayground
//

import Foundation
import Security

/// The student's Tier 2 (cloud) choices: whether it's on, consent, which courses may be sent,
/// and their own Gemini API key. Off by default. See Docs/Decisions/0001-tier2-cloud-provider.md.
///
/// Every property reads straight from `UserDefaults` or the Keychain, so it's safe to read from
/// any thread and a change takes effect on the very next request.
final class CloudSettings: @unchecked Sendable {
    static let shared = CloudSettings()

    static let defaultModel = "gemini-2.5-flash"

    private enum Key {
        static let enabled = "com.canvasPlus.cloud.enabled"
        static let consentAcceptedAt = "com.canvasPlus.cloud.consentAcceptedAt"
        static let optedInCourseIDs = "com.canvasPlus.cloud.optedInCourseIDs"
        static let model = "com.canvasPlus.cloud.model"
    }

    private let defaults: UserDefaults
    private let keyStore: CloudKeyStore

    init(defaults: UserDefaults = .standard, keyStore: CloudKeyStore = .keychain) {
        self.defaults = defaults
        self.keyStore = keyStore
    }

    var isEnabled: Bool {
        get { defaults.bool(forKey: Key.enabled) }
        set { defaults.set(newValue, forKey: Key.enabled) }
    }

    /// When the student accepted the consent screen. `nil` means they haven't.
    var consentAcceptedAt: Date? {
        get { defaults.object(forKey: Key.consentAcceptedAt) as? Date }
        set { defaults.set(newValue, forKey: Key.consentAcceptedAt) }
    }

    /// Courses whose content may be sent. Empty until the student picks some.
    var optedInCourseIDs: Set<String> {
        get { Set(defaults.stringArray(forKey: Key.optedInCourseIDs) ?? []) }
        set { defaults.set(newValue.sorted(), forKey: Key.optedInCourseIDs) }
    }

    var model: String {
        get { defaults.string(forKey: Key.model) ?? Self.defaultModel }
        set { defaults.set(newValue, forKey: Key.model) }
    }

    var apiKey: String? {
        keyStore.read().flatMap { $0.isEmpty ? nil : $0 }
    }

    var hasAPIKey: Bool { apiKey != nil }

    /// Saves the key, or removes it when `key` is nil or blank.
    func setAPIKey(_ key: String?) {
        let trimmed = key?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        keyStore.write(trimmed.isEmpty ? nil : trimmed)
    }

    func setCourse(_ courseID: String, optedIn: Bool) {
        var courses = optedInCourseIDs
        if optedIn { courses.insert(courseID) } else { courses.remove(courseID) }
        optedInCourseIDs = courses
    }

    /// On, consented, and has a key. Course opt-in is checked per request.
    var isReady: Bool {
        isEnabled && consentAcceptedAt != nil && hasAPIKey
    }

    /// Turns cloud off and forgets consent, opted-in courses and the key.
    func reset() {
        isEnabled = false
        consentAcceptedAt = nil
        optedInCourseIDs = []
        setAPIKey(nil)
    }
}

/// Where the API key lives. The app uses the Keychain; tests use memory.
struct CloudKeyStore: Sendable {
    var read: @Sendable () -> String?
    var write: @Sendable (String?) -> Void

    static let keychain = CloudKeyStore(
        read: {
            var item: CFTypeRef?
            let query = baseQuery.merging([
                kSecMatchLimit as String: kSecMatchLimitOne,
                kSecReturnData as String: true
            ]) { _, new in new }
            guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
                  let data = item as? Data else {
                return nil
            }
            return String(data: data, encoding: .utf8)
        },
        write: { key in
            SecItemDelete(baseQuery as CFDictionary)
            guard let key else { return }

            let attributes = baseQuery.merging([
                kSecValueData as String: Data(key.utf8),
                // This device only, never in backups or iCloud Keychain.
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]) { _, new in new }
            let status = SecItemAdd(attributes as CFDictionary, nil)
            if status != errSecSuccess {
                LoggerService.main.error("[Cloud] Couldn't save the Gemini API key: \(status)")
            }
        }
    )

    /// For tests and previews.
    static func inMemory(_ initial: String? = nil) -> CloudKeyStore {
        let box = KeyBox(initial)
        return CloudKeyStore(read: { box.value }, write: { box.value = $0 })
    }

    private static let service = "com.canvasPlus.GeminiAPIKey"
    private static let baseQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: service
    ]

    private final class KeyBox: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: String?

        init(_ value: String?) { stored = value }

        var value: String? {
            get { lock.withLock { stored } }
            set { lock.withLock { stored = newValue } }
        }
    }
}
