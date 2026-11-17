//
//  ActionExecutor.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation

/// Carries out a `ProposedAction` after the student approves it.
@MainActor
protocol ActionExecutor {
    func execute(_ action: ProposedAction) async throws
}

enum ActionExecutionError: LocalizedError, Equatable {
    case unsupportedTarget
    case toDoNotFound

    var errorDescription: String? {
        switch self {
        case .unsupportedTarget:
            "This action doesn't work for that item."
        case .toDoNotFound:
            "Couldn't find that to-do anymore. Refresh your to-do list and try again."
        }
    }
}
