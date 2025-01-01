//
//  GetFoldersInFolderRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/20/24.
//

import Foundation

struct GetFoldersInFolderRequest: CacheableArrayAPIRequest {
    typealias Subject = FolderAPI
    
    let folderId: String

    var path: String { "folders/\(folderId)/folders" }
    var queryParameters: [QueryParameter] {
        [("per_page", perPage)]
    }

    // MARK: Query Params
    let perPage: Int

    init(folderId: String, perPage: Int = 50) {
        self.folderId = folderId
        self.perPage = perPage
    }

    // MARK: request Id
    var requestId: Int? { folderId.asInt }
    var requestIdKey: ParentKeyPath<Folder, Int?> { .createWritable(\.parentFolderId) }
    var idPredicate: Predicate<Folder> {
        #Predicate<Folder> { folder in
            folder.parentFolderId == requestId
        }
    }
    var customPredicate: Predicate<Folder> {
        .true
    }
}
