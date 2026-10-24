//
//  ListToDosTool.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/8/26.
//

import Foundation
import FoundationModels

/// Lists the student's Canvas to-do items: overdue work first, then soonest due.
@available(iOS 26.0, macOS 26.0, *)
struct ListToDosTool: AgentTool {
    @Generable
    struct Arguments {
        @Guide(description: "Only include to-dos due within this many days from now (overdue ones are always included). Leave empty for all.")
        var daysAhead: Int?
    }

    let name = "listToDos"
    let description = "Lists the student's to-do items from Canvas with due dates. Overdue items come first."

    let dataSource: any AgentDataSource
    var now: @Sendable () -> Date = { .now }

    func evidence(for arguments: Arguments) async throws -> [Evidence] {
        let now = now()
        let horizon = arguments.daysAhead.map { now.addingTimeInterval(TimeInterval(max($0, 0)) * 86_400) }

        let toDos = try await dataSource.toDos().filter { toDo in
            guard let dueDate = toDo.facts.dueDate else { return horizon == nil }
            return dueDate < now || (horizon.map { dueDate <= $0 } ?? true)
        }

        // Ascending due date puts overdue work first; undated items go last.
        return Array(
            toDos
                .sorted { ($0.facts.dueDate ?? .distantFuture) < ($1.facts.dueDate ?? .distantFuture) }
                .prefix(AgentReadTools.maxResults)
        )
    }
}
