//
//  Cacheable.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 11/1/24.
//

import Foundation
import SwiftData

protocol BaseCacheable {}

class NoOpCacheable: BaseCacheable {}

protocol Cacheable: BaseCacheable, PersistentModel {
    var id: String { get }

    func merge(with other: Self)
}

extension Cacheable where Self: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Cacheable where Self: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
