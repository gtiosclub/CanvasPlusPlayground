// swiftlint:disable:this file_name

//
//  ChangeModels.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 10/25/26.
//

import Foundation

struct AccountKey: Codable, Hashable, Sendable {
    /// Lowercased DNS name, followed by `:port` unless the port is 443.
    let host: String
    let userID: String

    enum ValidationError: Error {
        case invalidHost
        case emptyUserID
    }

    /// Creates a validated account key with a normalized host and user ID.
    /// - Parameter rawHost: Canvas hostname or HTTP(S) URL. IP literals are rejected.
    /// - Parameter rawUserID: Canvas user ID, trimmed before validation.
    init(rawHost: String, rawUserID: String) throws {
        let normalizedHost = rawHost.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlString = normalizedHost.contains("://") ? normalizedHost : "https://\(normalizedHost)"
        guard let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.user == nil, url.password == nil,
              var name = url.host?.lowercased() else {
            throw ValidationError.invalidHost
        }

        if name.hasSuffix(".") { name.removeLast() }
        let labels = name.split(separator: ".", omittingEmptySubsequences: false)
        guard !name.contains(":"),
              !labels.contains(where: \.isEmpty),
              let last = labels.last, !last.allSatisfy(\.isNumber) else {
            throw ValidationError.invalidHost
        }

        let port = url.port ?? (scheme == "https" ? 443 : 80)
        guard (1...65_535).contains(port) else {
            throw ValidationError.invalidHost
        }

        let userID = rawUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userID.isEmpty else {
            throw ValidationError.emptyUserID
        }

        self.host = port == 443 ? name : "\(name):\(port)"
        self.userID = userID
    }

    /// Decodes an account key using the same validation as direct construction.
    /// - Parameter decoder: Source of the persisted host and user ID.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedHost = try container.decode(String.self, forKey: .host)
        let decodedUserID = try container.decode(String.self, forKey: .userID)
        try self.init(rawHost: decodedHost, rawUserID: decodedUserID)
    }
}

struct TrackingIdentity: Hashable, Sendable {
    let account: AccountKey
    let credentialGeneration: UUID
}

enum ChangeItemType: String, Codable, Sendable {
    case assignment
    case announcement
}

struct ChangeItemKey: Codable, Hashable, Sendable {
    let account: AccountKey
    let courseID: String
    let itemType: ChangeItemType
    let itemID: String
}

enum ChangeField: String, Codable, CaseIterable, Sendable {
    case itemAdded
    case dueAt
    case lockAt
    case unlockAt
    case name
    case pointsPossible
    case descriptionHash
    case grade
}

enum ChangeValue: Codable, Equatable, Sendable {
    case null
    case boolean(Bool)
    case text(String)
    case number(Double)
    case date(Date)
    case descriptionHash(String)
    case grade(Grade)

    enum GradeStatus: String, Codable, Sendable {
        case ungraded
        case unposted
        case graded
        case excused
        case unavailable
    }

    struct Grade: Codable, Equatable, Sendable {
        let status: GradeStatus
        let score: Double?
        let grade: String?
        let gradedAt: Date?
    }
}

struct ChangeRecord: Codable, Equatable, Sendable {
    let itemKey: ChangeItemKey
    let field: ChangeField
    let oldValue: ChangeValue
    let newValue: ChangeValue
    let firstDetectedAt: Date
    let lastDetectedAt: Date
    let revision: UInt64
}

struct ChangeSnapshot: Codable, Equatable, Sendable {
    let itemKey: ChangeItemKey
    let displayTitle: String
    /// A missing field is unknown; `.null` is known empty, which every field except `name` allows.
    let values: [ChangeField: ChangeValue]
}

struct ChangeObservationResult: Equatable, Sendable {
    let snapshots: [ChangeSnapshot]
    let changes: [FieldChange]

    struct FieldChange: Equatable, Sendable {
        let itemKey: ChangeItemKey
        let field: ChangeField
        let oldValue: ChangeValue
        let newValue: ChangeValue
    }
}

extension ChangeValue {
    /// Decodes the `{"type": ..., "value": ...}` shape written by `encode(to:)`.
    /// - Parameter decoder: Source of one persisted value.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .type) {
        case .null:
            self = .null
        case .boolean:
            self = .boolean(try container.decode(Bool.self, forKey: .value))
        case .text:
            self = .text(try container.decode(String.self, forKey: .value))
        case .number:
            self = .number(try container.decode(Double.self, forKey: .value))
        case .date:
            self = .date(try container.decode(Date.self, forKey: .value))
        case .descriptionHash:
            self = .descriptionHash(try container.decode(String.self, forKey: .value))
        case .grade:
            self = .grade(try container.decode(Grade.self, forKey: .value))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .null:
            try container.encode(Kind.null, forKey: .type)
        case .boolean(let value):
            try container.encode(Kind.boolean, forKey: .type)
            try container.encode(value, forKey: .value)
        case .text(let value):
            try container.encode(Kind.text, forKey: .type)
            try container.encode(value, forKey: .value)
        case .number(let value):
            try container.encode(Kind.number, forKey: .type)
            try container.encode(value, forKey: .value)
        case .date(let value):
            try container.encode(Kind.date, forKey: .type)
            try container.encode(value, forKey: .value)
        case .descriptionHash(let value):
            try container.encode(Kind.descriptionHash, forKey: .type)
            try container.encode(value, forKey: .value)
        case .grade(let value):
            try container.encode(Kind.grade, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    private enum Kind: String, Codable {
        case null
        case boolean
        case text
        case number
        case date
        case descriptionHash
        case grade
    }
}

extension ChangeSnapshot {
    /// Decodes values from the field-sorted entry array written by `encode(to:)`.
    /// - Parameter decoder: Source of one persisted snapshot.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        itemKey = try container.decode(ChangeItemKey.self, forKey: .itemKey)
        displayTitle = try container.decode(String.self, forKey: .displayTitle)
        let entries = try container.decode([Entry].self, forKey: .values)
        values = try Dictionary(entries.map { ($0.field, $0.value) }) { _, _ in
            throw DecodingError.dataCorruptedError(forKey: .values, in: container, debugDescription: "Duplicate field")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(itemKey, forKey: .itemKey)
        try container.encode(displayTitle, forKey: .displayTitle)
        let entries = values.map { Entry(field: $0.key, value: $0.value) }.sorted { $0.field.rawValue < $1.field.rawValue }
        try container.encode(entries, forKey: .values)
    }

    private enum CodingKeys: String, CodingKey {
        case itemKey
        case displayTitle
        case values
    }

    private struct Entry: Codable {
        let field: ChangeField
        let value: ChangeValue
    }
}
