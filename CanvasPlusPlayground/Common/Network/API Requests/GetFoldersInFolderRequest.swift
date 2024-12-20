//
//  GetFoldersInFolderRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/20/24.
//

import Foundation

struct GetFoldersInFolderRequest: ArrayAPIRequest {
    typealias Subject = Folder
    
    let folderId: String
    
    var path: String { "folders/\(folderId)/folders" }
    var queryParameters: [QueryParameter] {
        [("per_page", perPage)]
    }
    
    // MARK: Query Params
    let perPage: Int
    
    // MARK: request Id
    var requestId: Int? { folderId.asInt }
    var requestIdKey: ParentKeyPath<Folder, Int?> { .createWritable(\.parentFolderId) }
    var customPredicate: Predicate<Folder> {
        .true
    }
}
