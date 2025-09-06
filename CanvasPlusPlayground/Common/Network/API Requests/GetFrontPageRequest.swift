//
//  GetFrontPageRequest.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/25.
//

import Foundation

struct GetFrontPageRequest: CacheableAPIRequest {
    typealias Subject = PageAPI

    let courseId: String

    var path: String { "courses/\(courseId)/front_page" }

    var queryParameters: [QueryParameter] {
        []
    }

    init(courseId: String) {
        self.courseId = courseId
    }

    var requestId: String { "course_front_page" }
    var requestIdKey: ParentKeyPath<Page, String> { .createReadable(\.url) }

    var idPredicate: Predicate<Page> {
        #Predicate<Page> { page in
            page.courseID == courseId
        }
    }

    var customPredicate: Predicate<Page> { .true }
}
