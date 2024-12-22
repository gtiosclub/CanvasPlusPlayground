//
//  GetQuizzesRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/20/24.
//

import Foundation

struct GetQuizzesRequest: CacheableArrayAPIRequest {
    typealias Subject = Quiz
    
    let courseId: String
    var queryParameters: [QueryParameter] {
        [
            ("search_term", searchTerm),
            ("per_page", perPage)
        ]
    }
    
    var path: String { "courses/\(courseId)/all_quizzes" }
    
    // MARK: Query Params
    let searchTerm: String?
    let perPage: Int
    
    init(courseId: String, searchTerm: String? = nil, perPage: Int = 50) {
        self.courseId = courseId
        self.searchTerm = searchTerm
        self.perPage = perPage
    }
    
    var requestId: String { courseId }
    var requestIdKey: ParentKeyPath<Quiz, String> { .createWritable(\.parentId) }
    var idPredicate: Predicate<Quiz> {
        #Predicate<Quiz> { quiz in
            quiz.parentId == requestId
        }
    }
    var customPredicate: Predicate<Quiz> {
        let searchTerm = searchTerm ?? ""
        return #Predicate<Quiz> { quiz in
            quiz.title.contains(searchTerm)
        }
    }
}
