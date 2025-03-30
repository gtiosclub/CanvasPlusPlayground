//
//  GetUserTodoItemCountRequest.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/29/25.
//

import Foundation

struct GetUserTodoItemCountRequest: CacheableAPIRequest {
    typealias Subject = ToDoItemCountAPI

    var path: String { "users/self/todo_item_count" }

    var queryParameters: [QueryParameter] {
        include.map { ("include[]", $0.rawValue) }
    }

    // MARK: Query Params
    let include: [Include]

    init(include: [Include] = []) {
        self.include = include
    }

    var requestId: String {
        "todos_count_\(StorageKeys.accessTokenValue)"
    }

    var requestIdKey: ParentKeyPath<ToDoItemCount, String> {
        .createWritable(\.parentID)
    }

    var idPredicate: Predicate<ToDoItemCount> {
        #Predicate<ToDoItemCount> { item in
            item.parentID == requestId
        }
    }

    var customPredicate: Predicate<ToDoItemCount> {
        .true
    }
}

extension GetUserTodoItemCountRequest {
    enum Include: String {
        case ungradedQuizzes = "ungraded_quizzes"
    }
}
