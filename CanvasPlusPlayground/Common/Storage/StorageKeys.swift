//
//  StorageKeys.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import Foundation

enum StorageKeys {
    static let accessToken = "com.canvasPlus.AccessToken"
    static let installedModels = "com.canvasPlus.installedModels"

    static let baseKeychainQuery = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: accessToken,
        kSecAttrAccount as String: accessToken
    ] as [String : Any]

    static var accessTokenValue: String {
        get {
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

        set {
            SecItemDelete(baseKeychainQuery as CFDictionary)

            guard !newValue.isEmpty else {
                return
            }

            guard let tokenData = newValue.data(using: .utf8) else {
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
    }

    static var needsAuthorization: Bool {
        accessTokenValue.isEmpty
    }
}
