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
        let request = CanvasRequest.getToDoItemCount()

        do {
            let count: [ToDoItemCount]? = try await CanvasService.shared
                .loadAndSync(
                    request,
                    onCacheReceive: { cached in
                        guard let cached = cached?.first else { return }
                        self.toDoItemCount = cached.assignmentsNeedingSubmitting
                    }
                )

            self.toDoItemCount = count?.first?.assignmentsNeedingSubmitting
        } catch {
            LoggerService.main.error("Failed to fetch to-do item count: \(error)")
        }
    }

    func fetchToDoItems(courses: [Course]) async {
        let request = CanvasRequest.getToDoItems()

        var newItems = [ToDoItem]()

        do {
            let items: [ToDoItem]? = try await CanvasService.shared
                .loadAndSync(
                    request,
                    onCacheReceive: { cached in
                        guard let cached else { return }
                        toDoItems = cached
                    },
                    loadingMethod: .all(onNewPage: { items in
                        newItems.append(contentsOf: items)
                    })
                )
        } catch {
            LoggerService.main.error("Failed to fetch to-do items: \(error)")
        }

        newItems.forEach { item in
            item.course = courses.first { $0.id == item.courseID.asString }
        }

        toDoItems = newItems
    }

    func ignoreToDoItem(_ item: ToDoItem) async {
        let request = CanvasRequest.ignoreToDoItem(ignoreURL: item.ignoreURL)

        do {
            try await CanvasService.shared.fetch(request)
        } catch {
            LoggerService.main.error("Failed to ignore todo item: \(error)")
        }
    }
}
