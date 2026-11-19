//
//  ActionApprovalModel.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation

/// State for the shared approval UI. An action only runs when `approve` is called, which only
/// happens from a tap in `ProposedActionsView`.
@MainActor
@Observable
final class ActionApprovalModel {
    enum Status: Equatable {
        case pending
        case running
        case done
        case dismissed
        case failed(String)
    }

    struct Item: Identifiable {
        let action: ProposedAction
        var status: Status

        var id: UUID { action.id }
    }

    private(set) var items: [Item]
    private let executor: any ActionExecutor

    init(actions: [ProposedAction], executor: any ActionExecutor) {
        self.items = actions.map { Item(action: $0, status: .pending) }
        self.executor = executor
    }

    var pendingCount: Int {
        items.filter { $0.status == .pending }.count
    }

    func approve(_ id: UUID) async {
        guard let index = items.firstIndex(where: { $0.id == id }),
              items[index].status == .pending || isFailed(items[index].status) else {
            return
        }

        items[index].status = .running
        do {
            try await executor.execute(items[index].action)
            items[index].status = .done
        } catch {
            items[index].status = .failed(error.localizedDescription)
        }
    }

    func dismiss(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }), items[index].status != .running else {
            return
        }

        items[index].status = .dismissed
    }

    private func isFailed(_ status: Status) -> Bool {
        if case .failed = status { return true }
        return false
    }
}
