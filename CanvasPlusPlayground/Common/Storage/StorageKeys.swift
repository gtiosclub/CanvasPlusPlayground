//
//  StorageKeys.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import Foundation

enum StorageKeys {
    static let accessTokenKey = "com.canvasPlus.AccessToken"
    static let installedModelsKey = "com.canvasPlus.installedModels"

    static let baseKeychainQuery = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: accessTokenKey,
        kSecAttrAccount as String: accessTokenKey
    ] as [String : Any]

    static var accessTokenValue: String {
        get {
            // TODO: remove this block after April 10
            // For beta users that have tokens in `UserDefaults`
            if let token = UserDefaults.standard.string(forKey: accessTokenKey) {
                UserDefaults.standard.removeObject(forKey: accessTokenKey)
                setNewAccessToken(token)
            }
            // dont remove after this line

            return getAccessToken()
        }

        set {
            setNewAccessToken(newValue)
        }
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

    static func setNewAccessToken(_ token: String) {
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
}
