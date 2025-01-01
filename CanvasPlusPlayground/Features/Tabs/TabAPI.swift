//
//  TabAPI.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/16/24.
//

import Foundation

struct TabAPI: APIResponse {
    typealias Model = NoOpCacheable

    // swiftlint:disable identifier_name
    let id: String?
    let html_url: String?
    let full_url: String?
    let position: Int?
    let visibility: String?
    let label: String?
    let type: String?
    let url: String?
    // swiftlint:enable identifier_name

    // MARK: Custom for Model
    // var courseId: String?
}
