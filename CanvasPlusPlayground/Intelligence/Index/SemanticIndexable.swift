//
//  SemanticIndexable.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 10/19/26.
//

import Foundation
import PDFKit
import SwiftData

/// A plain-value copy of a model's indexable content, safe to hand off the main actor.
struct IndexSource: Hashable, Sendable {
    enum Content: Hashable, Sendable {
        case html(String)
        case plainText(String)
        /// A downloaded file; its text is extracted off the main actor at index time.
        case file(URL)
    }

    let sourceID: String
    let courseID: String?
    let title: String?
    let content: Content
    /// Identifies this version of the content. When it matches what's stored, the indexer
    /// skips the source without extracting or chunking it. Nil means always re-check.
    let revision: String?

    /// - Parameters:
    ///   - sourceID: Stable identifier, e.g. `"page:123"`.
    ///   - courseID: The owning course, used to scope search and eviction.
    ///   - title: Outermost heading for every chunk.
    ///   - html: The model's HTML body. Nil or blank means there is nothing to index.
    init?(sourceID: String, courseID: String?, title: String?, html: String?) {
        guard let html, !html.allSatisfy(\.isWhitespace) else { return nil }
        self.init(sourceID: sourceID, courseID: courseID, title: title, content: .html(html))
    }

    init(sourceID: String, courseID: String?, title: String?, content: Content, revision: String? = nil) {
        self.sourceID = sourceID
        self.courseID = courseID
        self.title = title
        self.content = content
        self.revision = revision
    }

    func chunks(using chunker: Chunker) -> [TextChunk] {
        switch content {
        case .html(let html):
            chunker.chunks(fromHTML: html, sourceID: sourceID, title: title)
        case .plainText(let text):
            chunker.chunks(fromPlainText: text, sourceID: sourceID, title: title)
        case .file(let url):
            Self.fileChunks(at: url, sourceID: sourceID, title: title, using: chunker)
        }
    }

    static let indexableFileExtensions: Set<String> = ["pdf", "txt", "md", "html", "htm"]

    private static func fileChunks(at url: URL, sourceID: String, title: String?, using chunker: Chunker) -> [TextChunk] {
        switch url.pathExtension.lowercased() {
        case "pdf":
            guard let document = PDFDocument(url: url) else { return [] }
            // Blank lines between pages make each page at least one block, so chunks don't straddle pages.
            let pages = (0..<document.pageCount).compactMap { document.page(at: $0)?.string }
            return chunker.chunks(fromPlainText: pages.joined(separator: "\n\n"), sourceID: sourceID, title: title)
        case "html", "htm":
            guard let html = try? String(contentsOf: url, encoding: .utf8) else { return [] }
            return chunker.chunks(fromHTML: html, sourceID: sourceID, title: title)
        case "txt", "md":
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
            return chunker.chunks(fromPlainText: text, sourceID: sourceID, title: title)
        default:
            return []
        }
    }
}

/// Models whose text belongs in the semantic index. Read on the main actor, where the models live.
protocol SemanticIndexable {
    /// - Parameter context: The context the model was fetched from, for models that need a related lookup.
    func indexSource(in context: ModelContext) -> IndexSource?
}

extension Page: SemanticIndexable {
    func indexSource(in context: ModelContext) -> IndexSource? {
        IndexSource(sourceID: "page:\(id)", courseID: courseID, title: title, html: body)
    }
}

extension Announcement: SemanticIndexable {
    func indexSource(in context: ModelContext) -> IndexSource? {
        IndexSource(sourceID: "announcement:\(id)", courseID: courseID, title: title, html: message)
    }
}

extension DiscussionTopic: SemanticIndexable {
    func indexSource(in context: ModelContext) -> IndexSource? {
        IndexSource(sourceID: "discussion:\(id)", courseID: courseId, title: title, html: message)
    }
}

extension Assignment: SemanticIndexable {
    func indexSource(in context: ModelContext) -> IndexSource? {
        IndexSource(sourceID: "assignment:\(id)", courseID: courseId.map(String.init), title: name, html: assignmentDescription)
    }
}

extension Quiz: SemanticIndexable {
    func indexSource(in context: ModelContext) -> IndexSource? {
        IndexSource(sourceID: "quiz:\(id)", courseID: courseID, title: title, html: details)
    }
}

extension Course: SemanticIndexable {
    func indexSource(in context: ModelContext) -> IndexSource? {
        IndexSource(sourceID: "syllabus:\(id)", courseID: id, title: name.map { "\($0) Syllabus" } ?? "Syllabus", html: syllabusBody)
    }
}

extension File: SemanticIndexable {
    /// Only files the student has downloaded are indexed; nothing is fetched for the index's sake.
    func indexSource(in context: ModelContext) -> IndexSource? {
        indexSource(courseID: courseID(in: context))
    }

    /// - Parameter courseID: The owning course, when the caller already knows it (e.g. right after a download).
    func indexSource(courseID: String?) -> IndexSource? {
        guard let localURL,
              IndexSource.indexableFileExtensions.contains(localURL.pathExtension.lowercased()),
              FileManager.default.fileExists(atPath: localURL.path(percentEncoded: false))
        else { return nil }

        let revision = "\(updatedAt?.timeIntervalSince1970 ?? 0)-\(size ?? 0)"
        return IndexSource(sourceID: "file:\(id)", courseID: courseID, title: displayName, content: .file(localURL), revision: revision)
    }

    private func courseID(in context: ModelContext) -> String? {
        guard let folderId else { return nil }
        let folderID = String(folderId)
        let folder = try? context.fetch(FetchDescriptor<Folder>(predicate: #Predicate { $0.id == folderID })).first
        guard let folder, folder.contextType?.lowercased() == "course", let contextId = folder.contextId else { return nil }
        return String(contextId)
    }
}
