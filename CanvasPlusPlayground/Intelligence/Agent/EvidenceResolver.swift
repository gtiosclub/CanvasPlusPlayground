//
//  EvidenceResolver.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation

/// Re-reads the record behind an `EvidenceRef`, or returns `nil` if it no longer exists.
@MainActor
protocol EvidenceResolver: Sendable {
    func resolve(_ ref: EvidenceRef) async -> Evidence?
}

/// Resolves refs through an `AgentDataSource`, so the gate sees the same (cache-first) data the
/// tools do. Each list it fetches is kept for the resolver's lifetime, so checking many claims
/// against the same course only reads it once. Make a new resolver per gate pass.
@MainActor
final class DataSourceEvidenceResolver: EvidenceResolver {
    private let dataSource: any AgentDataSource
    private var cache: [String: [String: Evidence]] = [:]

    init(dataSource: any AgentDataSource) {
        self.dataSource = dataSource
    }

    func resolve(_ ref: EvidenceRef) async -> Evidence? {
        let key: String
        let load: () async throws -> [Evidence]

        switch ref {
        case .course:
            key = "courses"
            load = { try await self.dataSource.courses() }
        case .assignment(_, let courseID):
            key = "assignments:\(courseID)"
            load = { try await self.dataSource.assignments(courseID: courseID) }
        case .announcement(_, let courseID):
            key = "announcements:\(courseID)"
            load = { try await self.dataSource.announcements(courseID: courseID) }
        case .calendarEvent(_, let courseID):
            key = "events:\(courseID)"
            load = { try await self.dataSource.calendarEvents(courseID: courseID) }
        case .toDo:
            key = "todos"
            load = { try await self.dataSource.toDos() }
        case .file(_, let courseID):
            key = "files:\(courseID)"
            load = { try await self.dataSource.files(courseID: courseID) }
        }

        if cache[key] == nil {
            // A failed read means we can't confirm the record, which the gate treats as unresolvable.
            guard let records = try? await load() else { return nil }
            cache[key] = Dictionary(records.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        }

        return cache[key]?[ref.id]
    }
}
