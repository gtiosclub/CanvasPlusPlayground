//
//  GetFolderRequest.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/8/25.
//

import Foundation

struct GetFolderRequest: CacheableAPIRequest {
    typealias Subject = FolderAPI

    let folderId: String

    // MARK: Path
    var path: String { "folders/\(folderId)" }

    // MARK: Query Parameters
    var queryParameters: [QueryParameter] {
        []
    }

    // MARK: Initializer
    init(folderId: String) {
        self.folderId = folderId
    }

    // MARK: Request ID
    var requestId: String { folderId }
    var requestIdKey: ParentKeyPath<Folder, String> { .createReadable(\.id) }
    var idPredicate: Predicate<Folder> {
        #Predicate<Folder> { folder in
            folder.id == folderId
        }
    }

    var customPredicate: Predicate<Folder> {
        .true
    }
}
