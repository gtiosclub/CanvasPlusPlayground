//
//  Cacheable.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 11/1/24.
//

import SwiftData
import Foundation

protocol Cacheable: Codable, PersistentModel {
    associatedtype ServerID: Hashable
    var id: String { get }
    var parentId: String { get set }    
    
    
    func merge(with other: Self)
}


extension Cacheable {
    
    func update<V>(keypath: ReferenceWritableKeyPath<Self, V>, value: V) async {
        await CanvasService.shared.repository.update(model: self, keypath: keypath, value: value)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}

struct ParentKeyPath<K, V> {
    var writableKeyPath: ReferenceWritableKeyPath<K, V>?
    var readableKeyPath: KeyPath<K, V>
    
    static func createWritable(_ keyPath: ReferenceWritableKeyPath<K, V>) -> Self {
        ParentKeyPath(writableKeyPath: keyPath, readableKeyPath: keyPath)
    }
    
    static func createReadable(_ keyPath: KeyPath<K, V>) -> Self {
        ParentKeyPath(readableKeyPath: keyPath)
    }
}
