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

    var htmlUrl: URL
    var fullUrl: URL?
    var position: Int
    var visibility: String?
    var label: String
    var type: TabType
    var hidden: Bool?
    var url: URL?

    init(from tabApi: TabAPI) {
        self.id = tabApi.id
        self.htmlUrl = tabApi.html_url
        self.fullUrl = tabApi.full_url
        self.position = tabApi.position
        self.visibility = tabApi.visibility
        self.label = tabApi.label
        self.type = tabApi.type
        self.url = tabApi.url
    }

    func merge(with other: CanvasTab) {
        self.htmlUrl = other.htmlUrl
        self.fullUrl = other.fullUrl
        self.position = other.position
        self.visibility = other.visibility
        self.label = other.label
        self.type = other.type
        self.url = other.url
    }
}
