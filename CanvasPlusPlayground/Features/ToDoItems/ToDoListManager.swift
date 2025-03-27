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
}
