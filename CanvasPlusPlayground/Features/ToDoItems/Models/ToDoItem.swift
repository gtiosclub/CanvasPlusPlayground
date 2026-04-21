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

        // MARK: User-Created Properties
        /// `true` for items the user created locally (not from Canvas API).
        var isUserCreated: Bool
        var customTitle: String?
        var customDueDate: Date?
        var customUrgency: String?
        var eventLocation: String?

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
            // User-created items always use their custom title.
            if isUserCreated { return customTitle ?? "Unknown Item" }
            return assignmentAPI?.name ?? quizAPI?.title ?? customTitle ?? "Unknown Item"
        }

        var dueDate: Date? {
            assignmentAPI?.dueDate ?? quizAPI?.due_at ?? customDueDate
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
            self.isUserCreated = false
        }

        /// Creates a locally-authored todo item (not backed by the Canvas API).
        init(
            courseID: Int,
            contextName: String,
            title: String,
            dueDate: Date? = nil,
            urgency: String? = nil,
            location: String? = nil
        ) {
            self.id = UUID().uuidString
            self.parentID = ""
            self.contextType = .course
            self.courseID = courseID
            self.groupID = nil
            self.contextName = contextName
            self.type = .submitting
            self.ignoreURL = ""
            self.ignorePermanentlyURL = ""
            self.htmlURL = ""
            self.isUserCreated = true
            self.customTitle = title
            self.customDueDate = dueDate
            self.customUrgency = urgency
            self.eventLocation = location
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
        // Never overwrite user-created metadata from an API sync
        if !self.isUserCreated {
            self.isUserCreated = other.isUserCreated
            self.customTitle = other.customTitle
            self.customDueDate = other.customDueDate
            self.customUrgency = other.customUrgency
            self.eventLocation = other.eventLocation
        }
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
