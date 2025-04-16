//
//  PickableItem.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/21/25.
//

import Foundation

protocol PickableItem {
    var itemTitle: String { get }
    var contents: String { get }
}

extension PickableItem where Self: Equatable { }

extension DiscussionTopic: PickableItem {
    var itemTitle: String {
        self.title ?? ""
    }

    var contents: String {
        self.message ?? ""
    }
}

extension File: PickableItem {
    var itemTitle: String {
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
    var itemTitle: String {
        self.displayTitle
    }

    var contents: String {
        self.body ?? ""
    }
}
