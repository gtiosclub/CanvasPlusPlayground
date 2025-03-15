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
    let include: [Include]
    let replacementChainContextType: String?
    let replacementChainContextId: Int?

    // MARK: Path
    var path: String { "files/\(fileId)" }

    // MARK: Query Parameters
    var queryParameters: [QueryParameter] {
        [
            ("replacement_chain_context_type", replacementChainContextType),
            ("replacement_chain_context_id", replacementChainContextId?.description)
        ]
        + include.map { ("include[]", $0.rawValue) }
    }

    var body: Data? { nil }

    // MARK: Initializer
    init(
        fileId: String,
        include: [Include] = [],
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
    var requestIdKey: ParentKeyPath<File, String> { .createReadable(\.id) }
    var idPredicate: Predicate<File> {
        #Predicate<File> { file in
            file.id == fileId
        }
    }

    var customPredicate: Predicate<File> {
        .true
    }
}

extension GetFileRequest {
    enum Include: String {
        case user,
            usageRights = "usage_rights"
    }
}
