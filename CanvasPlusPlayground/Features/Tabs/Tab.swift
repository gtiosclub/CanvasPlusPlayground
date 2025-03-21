//
//  Tab.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 3/21/25.
//

import Foundation
import SwiftData

@Model
class Tab: Cacheable {
    typealias ID = String

    @Attribute(.unique)
    var id: String
    var htmlUrl: String?
    var fullUrl: String?
    var position: Int?
    var visibility: String?
    var label: String?
    var type: String?
    var url: String?
    init(from other: TabAPI) {
        self.id = other.id!
        self.htmlUrl = other.html_url
        self.fullUrl = other.full_url
        self.position = other.position
        self.visibility = other.visibility
        self.label = other.label
        self.type = other.type
        self.url = other.url
        self.isUserHidden = false
    }

    func merge(with other: Tab) {
        self.htmlUrl = other.htmlUrl
        self.fullUrl = other.fullUrl
        self.position = other.position
        self.visibility = other.visibility
        self.label = other.label
        self.type = other.type
        self.url = other.url
        self.isUserHidden = other.isUserHidden
    }

    // MARK: Custom
    var isUserHidden: Bool
}
