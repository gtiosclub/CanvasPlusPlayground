//
//  Cacheable.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 11/1/24.
//

import SwiftData
import Foundation

protocol BaseCacheable {}

class NoOpCacheable: BaseCacheable {}

protocol Cacheable: BaseCacheable, PersistentModel {
    var id: String { get }

    func merge(with other: Self)
}

extension Cacheable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}
