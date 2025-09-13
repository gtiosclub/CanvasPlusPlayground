//
//  GetAllCourseFilesRequest.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 9/13/25.
//

import Foundation

struct GetAllCourseFilesRequest: CacheableArrayAPIRequest {
    typealias Subject = FileAPI

    let courseId: String

    var path: String { "courses/\(courseId)/files" }
    var queryParameters: [QueryParameter] {
        [
            ("search_term", searchTerm),
            ("per_page", perPage)
        ]
    }

    let searchTerm: String?
    let perPage: Int

    init(courseId: String, searchTerm: String?, perPage: Int =  50) {
        self.courseId = courseId
        self.searchTerm = searchTerm
        self.perPage = perPage
    }

    var requestId: Int? { courseId.asInt }

    var requestIdKey: ParentKeyPath<File, Int?> { .createReadable(\.folderId) }

    var idPredicate: Predicate<File> {
        let rid = requestId
        return rid == nil ? .true : #Predicate<File> { file in
            file.folderId == rid
        }
    }

    var customPredicate: Predicate<File> {
        let searchValue = searchTerm ?? ""
        let searchPred = searchValue.isEmpty ? .true : #Predicate<File> { file in
            file.displayName.localizedStandardContains(searchValue)
        }
        return searchPred
    }
}
