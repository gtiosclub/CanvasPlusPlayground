//
//  GetUserTodoItemsRequest.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/24/25.
//

import Foundation

struct GetUserTodoItemsRequest: CacheableArrayAPIRequest {
    typealias Subject = ToDoItemAPI

    var path: String {
        "users/self/todo"
    }

    var queryParameters: [QueryParameter] {
        [
            ("per_page", 100)
        ]
        + include.map { ("include[]", $0.rawValue) }
    }

    // MARK: Query Params
    let include: [Include]

    init(include: [Include] = []) {
        self.include = include
    }

    var requestId: String {
        "todos_\(StorageKeys.accessTokenValue)"
    }

    var requestIdKey: ParentKeyPath<ToDoItem, String> {
        .createWritable(\.parentID)
    }

    var idPredicate: Predicate<ToDoItem> {
        #Predicate<ToDoItem> { item in
            item.parentID == requestId
        }
    }

    var customPredicate: Predicate<ToDoItem> {
        .true
    }
}

extension GetUserTodoItemsRequest {
    enum Include: String {
        case ungradedQuizzes = "ungraded_quizzes"
    }
}
