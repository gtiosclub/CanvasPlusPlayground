//
//  GetModulesRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/3/25.
//

import Foundation

struct GetModulesRequest: CacheableArrayAPIRequest {
    typealias Subject = APIModule

    let courseId: String

    var path: String { "courses/\(courseId)/modules" }
    var queryParameters: [QueryParameter] {
        [
            ("search_term", searchTerm),
            ("per_page", perPage)
        ]
        + include.map { ("include[]", $0.rawValue) }
    }

    // MARK: Query Params
    let searchTerm: String?
    let include: [Include]
    let perPage: Int

    enum Include: String {
        case items, contentDetails = "content_details"
    }

    var requestId: String? { courseId }
    var requestIdKey: ParentKeyPath<Module, String?> {
        .createWritable(\.courseID)
    }
    var idPredicate: Predicate<Module> {
        #Predicate { $0.courseID == requestId }
    }
    var customPredicate: Predicate<Module> {
        let searchTerm = searchTerm ?? ""
        let searchPred = self.searchTerm == nil ? .true : #Predicate<Module> { module in
            module.name.localizedStandardContains(searchTerm)
        }

        return searchPred
    }

}
