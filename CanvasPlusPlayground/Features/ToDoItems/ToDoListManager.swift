//
//  ToDoListManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/24/25.
//

import SwiftUI

@Observable
class ToDoListManager {
    var toDoItems: [ToDoItem] = []
    var toDoItemCount: Int?

    func fetchToDoItemCount() async {
        let request = CanvasRequest.getToDoItemCount(
            include: [.ungradedQuizzes]
        )

        do {
            let count: [ToDoItemCount]? = try await CanvasService.shared
                .loadAndSync(
                    request,
                    onCacheReceive: { cached in
                        guard let cached = cached?.first else { return }
                        self.toDoItemCount = cached.assignmentsNeedingSubmitting
                    }
                )

            // TODO: If we support grading assignments, add that count
            self.toDoItemCount = count?.first?.assignmentsNeedingSubmitting
        } catch {
            LoggerService.main.error("Failed to fetch to-do item count: \(error)")
        }
    }

    func fetchToDoItems(courses: [Course]) async {
        let request = CanvasRequest.getToDoItems(include: [.ungradedQuizzes])

        var newItems = [ToDoItem]()

        do {
            let _: [ToDoItem]? = try await CanvasService.shared
                .loadAndSync(
                    request,
                    onCacheReceive: { cached in
                        guard let cached else { return }
                        toDoItems = []
                        self.addItems(cached, to: &toDoItems, courses: courses)
                    },
                    loadingMethod: .all(onNewPage: { items in
                        self.addItems(items, to: &newItems, courses: courses)
                    })
                )
        } catch {
            LoggerService.main.error("Failed to fetch to-do items: \(error)")
        }

        toDoItems = newItems
    }

    func ignoreToDoItem(_ item: ToDoItem) async {
        // We can either use the ignoreURL or the ignorePermanentlyURL.
        // ignoreURL will add the item back if the item is updated in the future.
        // ignorePermanentlyURL will remove the item from the list forever.

        let request = CanvasRequest.ignoreToDoItem(ignoreURL: item.ignoreURL)

        do {
            try await CanvasService.shared.fetch(request)
        } catch {
            LoggerService.main.error("Failed to ignore todo item: \(error)")
        }
    }

    private func addItems(
        _ newItems: [ToDoItem],
        to items: inout [ToDoItem],
        courses: [Course]
    ) {
        // TODO: If we support grading assignments, do not filter.
        let newItems = newItems.filter { $0.type == .submitting }

        newItems.forEach { item in
            item.course = courses.first { $0.id == item.courseID.asString }
        }

        items.append(contentsOf: newItems)
    }
}
