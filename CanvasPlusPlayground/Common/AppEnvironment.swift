//
//  AppEnvironment.swift
//  CanvasPlusPlayground
//
//  Global configuration for app environment (sandbox vs production).
//  Set to true for developers without API access to explore the app with static dummy data.
//
//  Created by Steven Liu on 1/31/26.
//

import Foundation

enum AppEnvironment {
    /// When true, the app runs in sandbox mode:
    /// - Skips authentication flow
    /// - Uses static dummy data for all course content
    /// - No network calls are made
    static let isSandbox = true
}
