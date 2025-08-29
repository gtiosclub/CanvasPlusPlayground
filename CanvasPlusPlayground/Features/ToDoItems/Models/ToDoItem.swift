//
//  ToDoItem.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/24/25.
//

import Foundation
import SwiftData

typealias ToDoItem = CanvasSchemaV1.ToDoItem

extension CanvasSchemaV1 {
    @Model
    class ToDoItem {
        typealias ID = String

        @Attribute(.unique)
        let id: String
        var parentID: String

        var contextType: ToDoItemContextType
        var courseID: Int
        var groupID: Int?
        var contextName: String
        var type: ToDoItemType
        var ignoreURL: String
        var ignorePermanentlyURL: String
        var assignment: Assignment?
        var quiz: Quiz?
        var htmlURL: String

        // MARK: Custom Properties
        @Transient
        var course: Course?

        // MARK: Computed Properties
        var title: String {
            assignment?.name ?? quiz?.title ?? "Unknown Item"
        }

        var dueDate: Date? {
            assignment?.dueDate ?? quiz?.dueAt
        }

        var itemType: TodoItemType? {
            if let assignment {
                return .assignment(assignment)
            } else if let quiz {
                return .quiz(quiz)
            }

            return nil
        }

        init(from toDoItemAPI: ToDoItemAPI) {
            self.id = toDoItemAPI.id
            self.parentID = ""
            self.contextType = toDoItemAPI.contextType
            self.courseID = toDoItemAPI.courseID
            self.groupID = toDoItemAPI.groupID
            self.contextName = toDoItemAPI.contextName
            self.type = toDoItemAPI.type
            self.ignoreURL = toDoItemAPI.ignoreURL
            self.ignorePermanentlyURL = toDoItemAPI.ignorePermanentlyURL
            self.assignment = toDoItemAPI.assignment?.createModel()
            self.quiz = toDoItemAPI.quiz?.createModel()
            self.htmlURL = toDoItemAPI.htmlURL
        }
    }
}

enum TodoItemType {
    case assignment(Assignment)
    case quiz(Quiz)
}

extension ToDoItem: Cacheable {
    func merge(with other: ToDoItem) {
        self.contextType = other.contextType
        self.courseID = other.courseID
        self.groupID = other.groupID
        self.contextName = other.contextName
        self.type = other.type
        self.ignoreURL = other.ignoreURL
        self.ignorePermanentlyURL = other.ignorePermanentlyURL
        self.assignment = other.assignment
        self.quiz = other.quiz
        self.htmlURL = other.htmlURL
    }
}
