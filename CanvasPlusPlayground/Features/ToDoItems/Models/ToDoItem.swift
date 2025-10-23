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
        var assignmentAPIData: Data?
        var quizAPIData: Data?
        var htmlURL: String

        // MARK: Custom Properties
        @Transient
        var course: Course?

        @Transient
        private var _assignmentAPICache: AssignmentAPI?

        @Transient
        private var _quizAPICache: QuizAPI?

        var assignmentAPI: AssignmentAPI? {
            get {
                if let cached = _assignmentAPICache {
                    return cached
                }
                guard let data = assignmentAPIData else { return nil }
                let decoded = try? JSONDecoder().decode(AssignmentAPI.self, from: data)
                _assignmentAPICache = decoded
                return decoded
            }
            set {
                _assignmentAPICache = newValue
                assignmentAPIData = newValue.flatMap { try? JSONEncoder().encode($0) }
            }
        }

        var quizAPI: QuizAPI? {
            get {
                if let cached = _quizAPICache {
                    return cached
                }
                guard let data = quizAPIData else { return nil }
                let decoded = try? JSONDecoder().decode(QuizAPI.self, from: data)
                _quizAPICache = decoded
                return decoded
            }
            set {
                _quizAPICache = newValue
                quizAPIData = newValue.flatMap { try? JSONEncoder().encode($0) }
            }
        }

        // MARK: Computed Properties
        var title: String {
            assignmentAPI?.name ?? quizAPI?.title ?? "Unknown Item"
        }

        var dueDate: Date? {
            assignmentAPI?.dueDate ?? quizAPI?.due_at
        }

        var itemType: TodoItemType? {
            if let assignmentAPI {
                return .assignmentAPI(assignmentAPI)
            } else if let quizAPI {
                return .quizAPI(quizAPI)
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
            self.assignmentAPIData = toDoItemAPI.assignment.flatMap { try? JSONEncoder().encode($0) }
            self.quizAPIData = toDoItemAPI.quiz.flatMap { try? JSONEncoder().encode($0) }
            self.htmlURL = toDoItemAPI.htmlURL
        }
    }
}

enum TodoItemType {
    case assignmentAPI(AssignmentAPI)
    case quizAPI(QuizAPI)
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
        self.assignmentAPIData = other.assignmentAPIData
        self.quizAPIData = other.quizAPIData
        self._assignmentAPICache = nil
        self._quizAPICache = nil
        self.htmlURL = other.htmlURL
    }
}

extension ToDoItem {
    func navigationDestination() -> NavigationModel.Destination? {
        if let type = self.itemType {
            switch type {
            case .assignmentAPI(let assignmentAPI):
                return .assignment(assignmentAPI.createModel())
            case .quizAPI(let quizAPI):
                return .quiz(quizAPI.createModel())
            }
        }

        return nil
    }
}
