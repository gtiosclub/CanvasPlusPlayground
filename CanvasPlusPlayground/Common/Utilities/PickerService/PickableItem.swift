//
//  PickableItem.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/21/25.
//

import Foundation

protocol PickableItem: Equatable {
    var contents: String { get }
}

extension DiscussionTopic: PickableItem {
    var contents: String {
        self.message ?? ""
    }
}

extension File: PickableItem {
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
    var contents: String {
        self.body ?? ""
    }
}
