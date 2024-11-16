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
    var parentId: String? { get set }    
    
    @MainActor
    func merge(with other: Self)
}


extension Cacheable {
    @MainActor
    func update<V>(keypath: ReferenceWritableKeyPath<Self, V>, value: V) {
        self[keyPath: keypath] = value        
    }
}