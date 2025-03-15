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
        + include.map { ("include[]", $0.rawValue) }
    }

    var body: Data? { nil }

    // MARK: Query Params
    let include: [Include]
    let perPage: Int

    init(courseId: String, include: [Include] = [], perPage: Int = 50) {
        self.courseId = courseId
        self.include = include
        self.perPage = perPage
    }
}

extension GetTabsRequest {
    enum Include: String {
        case courseSubjectTabs = "course_subject_tabs"
    }
}
