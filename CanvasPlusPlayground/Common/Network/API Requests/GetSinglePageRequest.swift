//
//  GetSinglePageRequest.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 4/8/25.
//

import Foundation

struct GetSinglePageRequest: CacheableAPIRequest {
    typealias Subject = PageAPI

    let courseId: String
    /// In most cases, this is the `url` parameter of the `Page`.
    let pageURL: String

    var path: String { "courses/\(courseId)/pages/\(pageURL)" }

    var queryParameters: [QueryParameter] {
        []
    }

    init(
        courseId: String,
        pageURL: String
    ) {
        self.courseId = courseId
        self.pageURL = pageURL
    }

    var requestId: String { pageURL }
    var requestIdKey: ParentKeyPath<Page, String> { .createReadable(\.url) }

    var idPredicate: Predicate<Page> {
        #Predicate<Page> { page in
            page.url == pageURL
        }
    }

    var customPredicate: Predicate<Page> { .true }
}
