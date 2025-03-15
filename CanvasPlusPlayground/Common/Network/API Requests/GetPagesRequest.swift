//
//  GetPagesRequest.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 2/21/25.
//

import Foundation

struct GetPagesRequest: CacheableArrayAPIRequest {
    typealias Subject = PageAPI

    let courseId: String

    var path: String { "courses/\(courseId)/pages" }

    var queryParameters: [QueryParameter] {
        [
            ("sort", sort),
            ("order", order),
            ("search_term", searchTerm),
            ("published", published),
            ("per_page", perPage)
        ]
        + include.map { ("include[]", $0.rawValue) }
    }

    var body: Data? { nil }

    // MARK: Query Params
    let sort: SortOption?
    let order: OrderOption?
    let searchTerm: String?
    let published: Bool?
    let include: [Include]
    let perPage: Int

    init(
        courseId: String,
        sort: SortOption? = nil,
        order: OrderOption? = nil,
        searchTerm: String? = nil,
        published: Bool? = nil,
        include: [Include] = [],
        perPage: Int = 50
    ) {
        self.courseId = courseId
        self.sort = sort
        self.order = order
        self.searchTerm = searchTerm
        self.published = published
        self.include = include
        self.perPage = perPage
    }

    var requestId: String? { courseId }
    var requestIdKey: ParentKeyPath<Page, String?> { .createWritable(\.courseID) }
    var idPredicate: Predicate<Page> {
        #Predicate<Page> { page in
            page.courseID == requestId
        }
    }

    var customPredicate: Predicate<Page> {
        let publishedPredicate: Predicate<Page>
        if let published {
            publishedPredicate = #Predicate<Page> { page in
                page.published == published
            }
        } else {
            publishedPredicate = .true
        }

        let searchTermPredicate: Predicate<Page>
        if let searchTerm, !searchTerm.isEmpty {
            searchTermPredicate = #Predicate<Page> { page in
                page.title?.contains(searchTerm) ?? false
            }
        } else {
            searchTermPredicate = .true
        }

        return #Predicate<Page> { page in
            page.courseID == requestId && publishedPredicate.evaluate(page) && searchTermPredicate.evaluate(page)
        }
    }
}

extension GetPagesRequest {
    enum Include: String {
        case body
    }
    enum SortOption: String {
        case title
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    enum OrderOption: String {
        case ascending = "asc"
        case descending = "desc"
    }
}
