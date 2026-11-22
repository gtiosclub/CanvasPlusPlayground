//
//  ToDoListManagerTests.swift
//  CanvasPlusPlaygroundTests
//

import Foundation
import SwiftData
import Testing
@testable import CanvasPlusPlayground

@MainActor
struct ToDoListManagerTests {
    @Test func completingCanvasItemRemovesItFromList() async throws {
        let manager = ToDoListManager()
        let item = try #require(SandboxData.dummyToDoItems.first)
        manager.toDoItems = [item]

        await manager.complete(item)

        #expect(manager.toDoItems.isEmpty)
    }

    @Test func completingUserCreatedItemDeletesItFromStore() async throws {
        let manager = ToDoListManager()
        let item = ToDoItem(courseID: 12345, contextName: "Example Course", title: "Test item")
        manager.addUserCreatedItem(item, course: nil)
        let id = item.id

        await manager.complete(item)

        #expect(manager.toDoItems.isEmpty)
        let stored = try ModelContext.shared.fetch(FetchDescriptor<ToDoItem>(predicate: #Predicate { $0.id == id }))
        #expect(stored.isEmpty)
    }
}
