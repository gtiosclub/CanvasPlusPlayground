//
//  StorageKeys.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import Foundation

enum StorageKeys {
    static let accessToken = "com.canvasPlus.AccessToken"

    static var accessTokenValue: String {
        get {
            UserDefaults.standard.string(forKey: accessToken) ?? ""
        }

        set {
            UserDefaults.standard.set(newValue, forKey: accessToken)
        }
    }

    static var needsAuthorization: Bool {
        accessTokenValue.isEmpty
    }
}
