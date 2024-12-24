//
//  DTO.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/22/24.
//

import Foundation

protocol APIResponse: Codable, Identifiable, Hashable {
    associatedtype Model: BaseCacheable
    
    func createModel() -> Model
}

// MARK: Hashable
extension APIResponse {
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
