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
            // A new reminder of its own, so it adds to (never replaces) ones the student set by hand,
            // and shows up in My Reminders like any other.
            try await remindersManager.add(
                PersonalReminder(id: action.id, target: Self.reminderTarget(for: target.ref), title: target.title, timing: .absolute(date)),
                dueDate: target.facts.dueDate
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

    static func reminderTarget(for ref: EvidenceRef) -> PersonalReminder.Target {
        switch ref {
        case let .assignment(id, courseID): .assignment(id: id, courseID: courseID)
        case let .announcement(id, courseID): .announcement(id: id, courseID: courseID)
        case let .calendarEvent(uid, courseID): .calendarEvent(uid: uid, courseID: courseID)
        case let .toDo(id, _): .toDo(id: id)
        // Courses, files and anything added later: a reminder that isn't tied to an item.
        default: .personal
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
