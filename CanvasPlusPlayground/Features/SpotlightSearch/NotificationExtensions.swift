//
//  NotificationExtensions.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 3/30/26.
//
import Foundation

extension Notification.Name {
    static let openSpotlightSearch = Notification.Name("openSpotlightSearch")
    static let openSpotlightDeepLink = Notification.Name("openSpotlightDeepLink")
}

enum SpotlightDeepLinkUserInfoKey {
    static let identifier = "identifier"
}
