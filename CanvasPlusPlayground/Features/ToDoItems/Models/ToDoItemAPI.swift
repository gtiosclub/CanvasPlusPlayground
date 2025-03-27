//
//  ToDoItemAPI.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/24/25.
//

import Foundation

struct ToDoItemAPI: Identifiable, APIResponse {
    typealias Model = ToDoItem

    let contextType: ToDoItemContextType
    let courseID: Int
    let groupID: Int?
    let contextName: String
    let type: ToDoItemType
    let ignoreURL: String
    let ignorePermanentlyURL: String
    let assignment: AssignmentAPI?
    let quiz: QuizAPI?
    let htmlURL: String

    enum CodingKeys: String, CodingKey {
        case contextType = "context_type"
        case courseID = "course_id"
        case groupID = "group_id"
        case contextName = "context_name"
        case type
        case ignoreURL = "ignore"
        case ignorePermanentlyURL = "ignore_permanently"
        case assignment
        case quiz
        case htmlURL = "html_url"
    }

    // Not included with API Response, so we need to synthesize it.
    var id: String {
        if let assignmentID = assignment?.id.asString {
            return assignmentID
        } else if let quizID = quiz?.id.asString {
            return quizID
        }

        return UUID().uuidString
    }

    func createModel() -> ToDoItem {
        ToDoItem(from: self)
    }
}

enum ToDoItemContextType: String, Codable {
    case course = "Course"
    case group = "Group"
}

enum ToDoItemType: String, Codable {
    case grading
    case submitting
}
