//
//  GetTabsRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/20/24.
//

import Foundation

struct GetTabsRequest: ArrayAPIRequest {
    typealias Subject = TabAPI

    let courseId: String

    var path: String { "courses/\(courseId)/tabs" }

    var queryParameters: [QueryParameter] {
        [
            ("per_page", perPage)
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
}
