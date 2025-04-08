//
//  CanvasTab.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 4/8/25.
//

import SwiftData
import Foundation

@Model
class CanvasTab: Cacheable {
    var id: String

    var htmlRelativeUrl: URL
    var fullUrl: URL?
    var position: Int
    var visibility: String?
    var label: String
    var type: TabType
    var hidden: Bool?
    var url: URL?

    var htmlAbsoluteUrl: URL {
        GetTabsRequest.baseURL.appendingPathComponent(htmlRelativeUrl.path)
    }

    init(from tabApi: TabAPI, tabOrigin: TabOrigin) {
        self.id = "\(tabOrigin.key)_\(tabApi.id)"
        self.htmlRelativeUrl = tabApi.html_url
        self.fullUrl = tabApi.full_url
        self.position = tabApi.position
        self.visibility = tabApi.visibility
        self.label = tabApi.label
        self.type = tabApi.type
        self.url = tabApi.url
    }

    func merge(with other: CanvasTab) {
        self.htmlRelativeUrl = other.htmlRelativeUrl
        self.fullUrl = other.fullUrl
        self.position = other.position
        self.visibility = other.visibility
        self.label = other.label
        self.type = other.type
        self.url = other.url
    }

    enum TabOrigin {
        case group(id: String), course(id: String)

        var key: String {
            switch self {
            case .group(id: let id):
                return "group_\(id)"
            case .course(id: let id):
                return "course_\(id)"
            }
        }
    }
}

extension CanvasTab {
    static let sample1 = CanvasTab(from: .sample1, tabOrigin: .course(id: "3232"))
    static let sample2 = CanvasTab(from: .sample2, tabOrigin: .course(id: "3232"))
    static let sample3 = CanvasTab(from: .sample3, tabOrigin: .course(id: "3232"))
}
