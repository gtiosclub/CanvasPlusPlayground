//
//  GetFilesInFolderRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/20/24.
//

import Foundation

struct GetFilesInFolderRequest: ArrayAPIRequest {
    typealias Subject = File
    
    let folderId: String
    
    var path: String { "folders/\(folderId)/files" }
    var queryParameters: [QueryParameter] {
        [
            ("search_term", searchTerm),
            ("sort", sort),
            ("order", order),
            ("per_page", perPage)
        ]
        + contentTypes.map {("content_types[]", $0)}
        + excludeContentTypes.map {("exclude_content_types[]", $0)}
        + include.map {("include[]", $0)}
        + only.map {("only[]", $0)}
    }
    
    // MARK: Query Params
    let contentTypes: [String]
    let excludeContentTypes: [String]
    let searchTerm: String?
    let include: [String]
    let only: [String]
    let sort: String?
    let order: String?
    let perPage: Int
    
    // MARK: request Id
    var requestId: Int? { folderId.asInt }
    var requestIdKey: ParentKeyPath<File, Int?> { .createWritable(\.folderId) }
    var customPredicate: Predicate<File> {
        // TODO: match query params
        #Predicate<File> { file in
            true
        }
    }
}
