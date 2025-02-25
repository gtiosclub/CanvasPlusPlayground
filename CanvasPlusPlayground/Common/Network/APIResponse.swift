//
//  APIResponse.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/22/24.
//

import Foundation

protocol APIResponse: Codable {
    associatedtype Model: BaseCacheable

    func createModel() -> Model
}

struct Empty: APIResponse {
    typealias Model = NoOpCacheable
}

// MARK: Hashable
extension APIResponse where Self: Identifiable, Self: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// to avoid rewriting this for noops
extension APIResponse where Model: NoOpCacheable {
    func createModel() -> NoOpCacheable {
        NoOpCacheable()
    }
}
