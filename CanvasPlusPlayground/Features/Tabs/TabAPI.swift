//
//  TabAPI.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/16/24.
//

import Foundation

// swiftlint:disable commented_code identifier_name
// https://github.com/instructure/canvas-ios/blob/49a3e347116d623638c66b7adbcc946294faa212/Core/Core/Contexts/APITab.swift
// https://canvas.instructure.com/doc/api/tabs.html
struct TabAPI: APIResponse, Identifiable {
    typealias Model = NoOpCacheable

    let id: String
    let html_url: URL
    let full_url: URL?
    let position: Int
    let visibility: String?
    let label: String
    let type: TabType
    let hidden: Bool?
    let url: URL?
}

enum TabType: String, Codable {
    case external, `internal`
}

extension TabAPI {
    static let sample1 = TabAPI(
        id: "home",
        html_url: URL(string: "https://canvas.instructure.com/courses/12345")!,
        full_url: URL(string: "https://canvas.instructure.com/courses/12345"),
        position: 0,
        visibility: "public",
        label: "Home",
        type: .internal,
        hidden: false,
        url: URL(string: "/courses/12345")
    )

    static let sample2 = TabAPI(
        id: "modules",
        html_url: URL(string: "https://canvas.instructure.com/courses/12345/modules")!,
        full_url: URL(string: "https://canvas.instructure.com/courses/12345/modules"),
        position: 1,
        visibility: "public",
        label: "Modules",
        type: .internal,
        hidden: false,
        url: URL(string: "/courses/12345/modules")
    )

    static let sample3 = TabAPI(
        id: "assignments",
        html_url: URL(string: "https://canvas.instructure.com/courses/12345/assignments")!,
        full_url: URL(string: "https://canvas.instructure.com/courses/12345/assignments"),
        position: 2,
        visibility: "public",
        label: "Assignments",
        type: .internal,
        hidden: false,
        url: URL(string: "/courses/12345/assignments")
    )
}
