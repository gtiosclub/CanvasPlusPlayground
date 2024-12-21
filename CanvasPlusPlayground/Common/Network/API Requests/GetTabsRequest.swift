//
//  GetTabsRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/20/24.
//

import Foundation

struct GetTabsRequest: ArrayAPIRequest {
    typealias Subject = Tab
    
    let courseId: String
    
    var path: String { "courses/\(courseId)/tabs" }
    
    var queryParameters: [QueryParameter] {
        [
            ("per_page", perPage),
        ]
        + include.map { ("include[]", $0) }
    }
    
    // MARK: Query Params
    let include: [String]
    let perPage: Int
    
    init(courseId: String, include: [String] = [], perPage: Int = 50) {
        self.courseId = courseId
        self.include = include
        self.perPage = perPage
    }
    
    var requestId: String? { courseId }
    // TODO: create parent id for tab
    var requestIdKey: ParentKeyPath<Tab, String?> { .createWritable(\.courseId) }
    var idPredicate: Predicate<Tab> {
        #Predicate<Tab> { tab in
            tab.courseId == requestId
        }
    }
    var customPredicate: Predicate<Tab> {
        .true
    }
}
