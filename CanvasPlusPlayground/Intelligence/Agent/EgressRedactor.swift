//
//  EgressRedactor.swift
//  CanvasPlusPlayground
//

import Foundation
import SwiftData

/// Removes personal details from text before it leaves the device: email addresses, phone
/// numbers, and the names of other people (classmates, TAs, instructors) cached from rosters.
/// The student's own name is not in `names`, so it stays.
struct EgressRedactor: Sendable {
    static let emailPlaceholder = "[email]"
    static let phonePlaceholder = "[phone]"
    static let personPlaceholder = "[person]"

    private let namePattern: NSRegularExpression?

    /// - Parameter names: Full names to remove, in any order. Names shorter than two words are
    ///   ignored, since a single first name ("Will", "May") collides with ordinary words.
    init(names: [String]) {
        let usable = Set(
            names
                .map { $0.split(whereSeparator: \.isWhitespace).joined(separator: " ") }
                .filter { $0.split(separator: " ").count >= 2 }
        )
        // Longest first, so "Mary Ann Smith" goes before "Ann Smith".
        let alternatives = usable
            .sorted { $0.count != $1.count ? $0.count > $1.count : $0 < $1 }
            .map { NSRegularExpression.escapedPattern(for: $0).replacingOccurrences(of: " ", with: "\\s+") }

        namePattern = alternatives.isEmpty ? nil : try? NSRegularExpression(
            pattern: "(?<![\\p{L}\\p{N}])(?:\(alternatives.joined(separator: "|")))(?![\\p{L}\\p{N}])",
            options: [.caseInsensitive]
        )
    }

    func redact(_ text: String) -> String {
        var result = Self.replace(Self.emailPattern, in: text, with: Self.emailPlaceholder)
        result = Self.replace(Self.phonePattern, in: result, with: Self.phonePlaceholder)
        if let namePattern {
            result = Self.replace(namePattern, in: result, with: Self.personPlaceholder)
        }
        return result
    }

    private static let emailPattern = try! NSRegularExpression(
        pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}",
        options: [.caseInsensitive]
    )

    /// North American numbers with or without country code and separators, e.g. (404) 555-0100,
    /// 404.555.0100, +1 404 555 0100. Requires separators or parentheses so plain 10-digit ids
    /// (Canvas course and assignment ids) aren't mistaken for phone numbers.
    private static let phonePattern = try! NSRegularExpression(
        pattern: "(?<![\\d])(?:\\+?1[\\s.-])?(?:\\(\\d{3}\\)\\s?|\\d{3}[\\s.-])\\d{3}[\\s.-]\\d{4}(?![\\d])"
    )

    private static func replace(_ pattern: NSRegularExpression, in text: String, with template: String) -> String {
        pattern.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: NSRegularExpression.escapedTemplate(for: template)
        )
    }
}

extension EgressRedactor {
    /// A redactor for everyone in the cached rosters except the student.
    ///
    /// Roster entries are `User`s with a `courseId`; the student's own record (from `getUser`) has
    /// none, so anyone sharing its id is kept.
    @MainActor
    static func fromCachedRosters(in context: ModelContext? = nil) -> EgressRedactor {
        let context = context ?? .shared
        let users = (try? context.fetch(FetchDescriptor<User>())) ?? []
        let selfIDs = Set(users.filter { $0.courseId == nil }.map(\.id))
        let others = users.filter { $0.courseId != nil && !selfIDs.contains($0.id) }

        return EgressRedactor(names: others.flatMap { user in
            [user.name, user.shortName, Self.reordered(user.sortableName)]
        })
    }

    /// "Smith, Jane" → "Jane Smith"; anything else is returned as is.
    static func reordered(_ sortableName: String) -> String {
        let parts = sortableName.split(separator: ",", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        return parts.count == 2 ? "\(parts[1]) \(parts[0])" : sortableName
    }
}
