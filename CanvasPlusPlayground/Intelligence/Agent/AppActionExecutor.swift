//
//  AppActionExecutor.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/18/26.
//

import Foundation

/// Runs approved actions through the app's existing managers, so an approved agent action
/// behaves exactly like the same action done by hand.
@MainActor
final class AppActionExecutor: ActionExecutor {
    private let remindersManager: RemindersManager
    private let pinnedItemsManager: PinnedItemsManager
    private let toDoListManager: ToDoListManager

    init(
        remindersManager: RemindersManager,
        pinnedItemsManager: PinnedItemsManager = .shared,
        toDoListManager: ToDoListManager
    ) {
        self.remindersManager = remindersManager
        self.pinnedItemsManager = pinnedItemsManager
        self.toDoListManager = toDoListManager
    }

    func execute(_ action: ProposedAction) async throws {
        let target = action.target

        switch action.kind {
        case .reminder(let date):
            try await remindersManager.scheduleReminder(
                // Unique per proposal, so this can't replace a reminder the student set by hand.
                identifier: "agent-\(target.id)-\(action.id.uuidString)",
                title: "REMINDER: \(target.title)",
                body: target.facts.dueDate.map { "Due in \(Date.timeDeltaString(from: $0, to: date))" } ?? "",
                at: date
            )

        case .pin:
            guard let type = Self.pinnedItemType(for: target.ref.kind), let courseID = target.ref.courseID else {
                throw ActionExecutionError.unsupportedTarget
            }

            let itemID = target.ref.recordID
            let alreadyPinned = pinnedItemsManager.pinnedItems.contains { pinned in
                pinned.id == itemID && pinned.courseID == courseID && pinned.type == type
            }
            // `togglePinnedItem` would unpin something already pinned, so only toggle when it isn't.
            if !alreadyPinned {
                pinnedItemsManager.togglePinnedItem(itemID: itemID, courseID: courseID, type: type)
            }

        case .markToDoDone:
            guard let item = toDoListManager.toDoItems.first(where: { $0.id == target.ref.recordID }) else {
                throw ActionExecutionError.toDoNotFound
            }

            await toDoListManager.ignoreToDoItem(item)
            toDoListManager.toDoItems.remove(item)
        }
    }

    static func pinnedItemType(for kind: EvidenceKind) -> PinnedItem.PinnedItemType? {
        switch kind {
        case .assignment:
            .assignment
        case .announcement:
            .announcement
        case .file:
            .file
        case .calendarEvent:
            .calendarEvent
        case .course, .toDo:
            nil
        }
    }
}
