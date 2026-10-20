//
//  SemanticIndexable.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 10/19/26.
//

import Foundation

/// A plain-value copy of a model's indexable content, safe to hand off the main actor.
struct IndexSource: Hashable, Sendable {
    enum Content: Hashable, Sendable {
        case html(String)
        case plainText(String)
    }

    let sourceID: String
    let courseID: String?
    let title: String?
    let content: Content

    /// - Parameters:
    ///   - sourceID: Stable identifier, e.g. `"page:123"`.
    ///   - courseID: The owning course, used to scope search and eviction.
    ///   - title: Outermost heading for every chunk.
    ///   - html: The model's HTML body. Nil or blank means there is nothing to index.
    init?(sourceID: String, courseID: String?, title: String?, html: String?) {
        guard let html, !html.allSatisfy(\.isWhitespace) else { return nil }
        self.init(sourceID: sourceID, courseID: courseID, title: title, content: .html(html))
    }

    init(sourceID: String, courseID: String?, title: String?, content: Content) {
        self.sourceID = sourceID
        self.courseID = courseID
        self.title = title
        self.content = content
    }

    func chunks(using chunker: Chunker) -> [TextChunk] {
        switch content {
        case .html(let html):
            chunker.chunks(fromHTML: html, sourceID: sourceID, title: title)
        case .plainText(let text):
            chunker.chunks(fromPlainText: text, sourceID: sourceID, title: title)
        }
    }
}

/// Models whose text belongs in the semantic index. Read on the main actor, where the models live.
protocol SemanticIndexable {
    var indexSource: IndexSource? { get }
}

extension Page: SemanticIndexable {
    var indexSource: IndexSource? {
        IndexSource(sourceID: "page:\(id)", courseID: courseID, title: title, html: body)
    }
}

extension Announcement: SemanticIndexable {
    var indexSource: IndexSource? {
        IndexSource(sourceID: "announcement:\(id)", courseID: courseID, title: title, html: message)
    }
}

extension DiscussionTopic: SemanticIndexable {
    var indexSource: IndexSource? {
        IndexSource(sourceID: "discussion:\(id)", courseID: courseId, title: title, html: message)
    }
}

extension Assignment: SemanticIndexable {
    var indexSource: IndexSource? {
        IndexSource(sourceID: "assignment:\(id)", courseID: courseId.map(String.init), title: name, html: assignmentDescription)
    }
}

extension Quiz: SemanticIndexable {
    var indexSource: IndexSource? {
        IndexSource(sourceID: "quiz:\(id)", courseID: courseID, title: title, html: details)
    }
}

extension Course: SemanticIndexable {
    var indexSource: IndexSource? {
        IndexSource(sourceID: "syllabus:\(id)", courseID: id, title: name.map { "\($0) Syllabus" } ?? "Syllabus", html: syllabusBody)
    }
}
