//
//  GetModuleItemsRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/4/25.
//

import Foundation

struct GetModuleItemsRequest: CacheableArrayAPIRequest {
    typealias Subject = APIModuleItem

    let courseId: String
    let moduleId: String

    var path: String { "courses/\(courseId)/modules/\(moduleId)/items" }
    var queryParameters: [QueryParameter] {
        [
            ("search_term", searchTerm),
            ("per_page", perPage)
        ]
        + include.map { ("include[]", $0.rawValue) }
    }

    let include: [Include]
    let searchTerm: String?
    let perPage: Int

    var requestId: String? { "\(courseId)_\(moduleId)" }
    var requestIdKey: ParentKeyPath<ModuleItem, String?> {
        .createWritable(\.parentId)
    }
    var idPredicate: Predicate<ModuleItem> {
        #Predicate {
            $0.parentId == requestId
        }
    }
    var customPredicate: Predicate<ModuleItem> {
        let searchTerm = searchTerm ?? ""
        return self.searchTerm == nil ? .true : #Predicate<ModuleItem> { moduleItem in
            moduleItem.title.localizedStandardContains(searchTerm)
        }
    }
}

extension GetModuleItemsRequest {
    enum Include: String {
        case contentDetails = "content_details"
    }
}
