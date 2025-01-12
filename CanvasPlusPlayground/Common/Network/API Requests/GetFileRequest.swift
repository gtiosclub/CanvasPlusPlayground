//
//  GetFileRequest.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 1/8/25.
//

import Foundation

struct GetFileRequest: CacheableAPIRequest {
    typealias Subject = FileAPI

    let fileId: String
    let include: [String]
    let replacementChainContextType: String?
    let replacementChainContextId: Int?

    // MARK: Path
    var path: String { "files/\(fileId)" }

    // MARK: Query Parameters
    var queryParameters: [QueryParameter] {
        [
            ("include[]", include.joined(separator: ",")),
            ("replacement_chain_context_type", replacementChainContextType),
            ("replacement_chain_context_id", replacementChainContextId?.description)
        ]
    }

    // MARK: Initializer
    init(
        fileId: String,
        include: [String] = [],
        replacementChainContextType: String? = nil,
        replacementChainContextId: Int? = nil
    ) {
        self.fileId = fileId
        self.include = include
        self.replacementChainContextType = replacementChainContextType
        self.replacementChainContextId = replacementChainContextId
    }

    // MARK: Request ID
    var requestId: String { fileId }
    var requestIdKey: ParentKeyPath<File, String> { .createWritable(\.id) }
    var idPredicate: Predicate<File> {
        #Predicate<File> { file in
            file.id == fileId
        }
    }

    var customPredicate: Predicate<File> {
        .true
    }
}
