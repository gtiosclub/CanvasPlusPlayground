//
//  PickableItem.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/21/25.
//

import Foundation

protocol PickableItem {
    var name: String { get }
    var contents: String { get }
}

extension PickableItem where Self: Equatable { }

/// Type-erased `PickableItem`
struct AnyPickableItem: PickableItem, Equatable {
    let name: String
    let contents: String

    init(name: String, contents: String) {
        self.name = name
        self.contents = contents
    }
}

extension DiscussionTopic: PickableItem {
    var name: String {
        self.title ?? ""
    }

    var contents: String {
        self.message ?? ""
    }
}

extension File: PickableItem {
    var name: String {
        self.displayName
    }

    var contents: String {
        CourseFileService.getContentsOfFile(at: self.localURL)
    }

    static var supportedPickableTypes: [String] {
        #if os(macOS)
        ["doc", "docx", "pdf", "txt", "html"]
        #else
        ["pdf", "txt", "html"]
        #endif
    }
}

extension Page: PickableItem {
    var name: String {
        self.displayTitle
    }

    var contents: String {
        self.body ?? ""
    }
}
