//
//  GetFilesInFolderRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/20/24.
//

import Foundation

struct GetFilesInFolderRequest: CacheableArrayAPIRequest {
    typealias Subject = FileAPI

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
    let contentTypes: [String?]
    let excludeContentTypes: [String?]
    let searchTerm: String?
    let include: [Include]
    let only: [Only]
    let sort: Sort?
    let order: Order?
    let perPage: Int

    init(
        folderId: String,
        contentTypes: [String?] = [],
        excludeContentTypes: [String?] = [],
        searchTerm: String? = nil,
        include: [Include] = [],
        only: [Only] = [],
        sort: Sort? = nil,
        order: Order? = nil,
        perPage: Int = 50
    ) {
        self.folderId = folderId
        self.contentTypes = contentTypes
        self.excludeContentTypes = excludeContentTypes
        self.searchTerm = searchTerm
        self.include = include
        self.only = only
        self.sort = sort
        self.order = order
        self.perPage = perPage
    }

    // MARK: request Id
    var requestId: Int? { folderId.asInt }
    var requestIdKey: ParentKeyPath<File, Int?> { .createWritable(\.folderId) }
    var idPredicate: Predicate<File> {
        #Predicate<File> { file in
            file.folderId == requestId
        }
    }
    var customPredicate: Predicate<File> {

        let contentTypePred = contentTypes.isEmpty ? .true : #Predicate<File> { file in
            contentTypes.contains(file.contentType)
        }

        let excludeContentTypesPred = excludeContentTypes.isEmpty ? .true : #Predicate<File> { file in
            !excludeContentTypes.contains(file.contentType)
        }

        let searchTerm = searchTerm ?? ""
        let searchPred = searchTerm.isEmpty ? .true : #Predicate<File> { file in
            file.displayName.localizedStandardContains(searchTerm)
        }

        return #Predicate<File> { file in
            contentTypePred.evaluate(file)
            && excludeContentTypesPred.evaluate(file)
            && searchPred.evaluate(file)
        }
    }
}

extension GetFilesInFolderRequest {
    enum Include: String {
        case user,
             usageRights = "usage_rights"
    }

    enum Only: String {
        case names
    }

    enum Sort: String {
        case name,
             size,
             createdAt = "created_at",
             updatedAt = "updated_at",
             contentType = "content_type",
             user
    }

    enum Order: String {
        case asc,
             desc
    }
}
