//
//  Tab.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/16/24.
//

import Foundation

// swiftlint:disable:next type_name
struct Tab: Codable {
    let id: String?
    let htmlURL: String?
    let fullURL: String?
    let position: Int?
    let visibility: String?
    let label: String?
    let type: String?
    let url: String?

    // MARK: Custom
    var courseId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case htmlURL = "html_url"
        case fullURL = "full_url"
        case position
        case visibility
        case label
        case type
        case url
    }
}
