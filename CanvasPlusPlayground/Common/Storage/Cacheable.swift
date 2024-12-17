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
    func parentIdFor(request: CanvasRequest) -> ParentKeyPath<Self, String>
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
    
    init(writableKeyPath: ReferenceWritableKeyPath<K, V>) {
        self.writableKeyPath = writableKeyPath
        self.readableKeyPath = writableKeyPath
    }
    
    init (readableKeyPath: KeyPath<K, V>) {
        self.readableKeyPath = readableKeyPath
    }
}
