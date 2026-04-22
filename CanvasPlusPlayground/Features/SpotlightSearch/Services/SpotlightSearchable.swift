//
//  SpotlightSearchable.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 3/29/26.
//

import CoreSpotlight
import UniformTypeIdentifiers

protocol SpotlightSearchable {
    static var spotlightDomainIdentifier : String {get}
    var spotlightUniqueIdentifier : String {get}
    var spotlightAttributeSet : CSSearchableItemAttributeSet {get}
}

extension SpotlightSearchable {
    func toSearchableItem() -> CSSearchableItem {
        CSSearchableItem(
            uniqueIdentifier: spotlightUniqueIdentifier,
            domainIdentifier: Self.spotlightDomainIdentifier,
            attributeSet: spotlightAttributeSet
        )
    }
}

// now conform each model type to this protocol for easy indexing

// MARK: - Course

extension Course: SpotlightSearchable {
    static var spotlightDomainIdentifier: String { "courses" }

    var spotlightUniqueIdentifier: String { "course:\(id)" }

    var spotlightAttributeSet: CSSearchableItemAttributeSet {
        let attrs = CSSearchableItemAttributeSet(contentType: .content)
        attrs.title = displayName
        attrs.contentDescription = courseCode
        attrs.keywords = [name, courseCode, nickname].compactMap { $0 }
        return attrs
    }
}

// MARK: - Assignment

extension Assignment: SpotlightSearchable {
    static var spotlightDomainIdentifier: String { "assignments" }

    var spotlightUniqueIdentifier: String { "assignment:\(id)" }

    var spotlightAttributeSet: CSSearchableItemAttributeSet {
        let attrs = CSSearchableItemAttributeSet(contentType: .content)
        attrs.title = name
        attrs.contentDescription = assignmentDescription
        if let dueDate {
            attrs.dueDate = dueDate
        }
        return attrs
    }
}

// MARK: - DiscussionTopic (Announcements)

extension DiscussionTopic: SpotlightSearchable {
    static var spotlightDomainIdentifier: String { "announcements" }

    var spotlightUniqueIdentifier: String { "announcement:\(id)" }

    var spotlightAttributeSet: CSSearchableItemAttributeSet {
        let attrs = CSSearchableItemAttributeSet(contentType: .content)
        attrs.title = title
        // `message` is HTML — strip tags for a cleaner Spotlight preview.
        // For now, use `summary` if available, else raw message.
        attrs.contentDescription = summary ?? message
        attrs.keywords = [userName].compactMap { $0 }
        if let date {
            attrs.completionDate = date  // closest built-in date field
        }
        return attrs
    }
}

// MARK: - Quiz

extension Quiz: SpotlightSearchable {
    static var spotlightDomainIdentifier: String { "quizzes" }

    var spotlightUniqueIdentifier: String { "quiz:\(id)" }

    var spotlightAttributeSet: CSSearchableItemAttributeSet {
        let attrs = CSSearchableItemAttributeSet(contentType: .content)
        attrs.title = title
        attrs.contentDescription = details
        if let dueAt {
            attrs.dueDate = dueAt
        }
        return attrs
    }
}

// MARK: - Page

extension Page: SpotlightSearchable {
    static var spotlightDomainIdentifier: String { "pages" }

    var spotlightUniqueIdentifier: String { "page:\(id)" }

    var spotlightAttributeSet: CSSearchableItemAttributeSet {
        let attrs = CSSearchableItemAttributeSet(contentType: .content)
        attrs.title = displayTitle
        // `body` is HTML — could strip tags for better preview
        attrs.contentDescription = body
        return attrs
    }
}

// MARK: - File

extension File: SpotlightSearchable {
    static var spotlightDomainIdentifier: String { "files" }

    var spotlightUniqueIdentifier: String { "file:\(id)" }

    var spotlightAttributeSet: CSSearchableItemAttributeSet {
        // Use the file's content type if available, fall back to generic
        let utType = contentType.flatMap { UTType(mimeType: $0) } ?? .content
        let attrs = CSSearchableItemAttributeSet(contentType: utType)
        attrs.title = displayName
        attrs.contentDescription = filename
        if let size {
            attrs.fileSize = NSNumber(value: size)
        }
        return attrs
    }
}

// MARK: - Module

extension Module: SpotlightSearchable {
    static var spotlightDomainIdentifier: String { "modules" }

    var spotlightUniqueIdentifier: String { "module:\(id)" }

    var spotlightAttributeSet: CSSearchableItemAttributeSet {
        let attrs = CSSearchableItemAttributeSet(contentType: .content)
        attrs.title = name
        attrs.contentDescription = "\(itemsCount) item\(itemsCount == 1 ? "" : "s")"
        return attrs
    }
}

// MARK: - User (People)

extension User: SpotlightSearchable {
    static var spotlightDomainIdentifier: String { "people" }

    var spotlightUniqueIdentifier: String { "person:\(id)" }

    var spotlightAttributeSet: CSSearchableItemAttributeSet {
        let attrs = CSSearchableItemAttributeSet(contentType: .contact)
        attrs.title = name
        attrs.contentDescription = email
        attrs.emailAddresses = [email].compactMap { $0 }
        attrs.displayName = shortName
        return attrs
    }
}

// MARK: - CanvasGroup

extension CanvasGroup: SpotlightSearchable {
    static var spotlightDomainIdentifier: String { "groups" }

    var spotlightUniqueIdentifier: String { "group:\(id)" }

    var spotlightAttributeSet: CSSearchableItemAttributeSet {
        let attrs = CSSearchableItemAttributeSet(contentType: .content)
        attrs.title = name
        attrs.contentDescription = groupDescription
        return attrs
    }
}

// MARK: - ToDoItem

extension ToDoItem: SpotlightSearchable {
    static var spotlightDomainIdentifier: String { "todos" }

    var spotlightUniqueIdentifier: String { "todo:\(id)" }

    var spotlightAttributeSet: CSSearchableItemAttributeSet {
        let attrs = CSSearchableItemAttributeSet(contentType: .content)
        attrs.title = title
        attrs.contentDescription = contextName
        if let dueDate {
            attrs.dueDate = dueDate
        }
        return attrs
    }
}
