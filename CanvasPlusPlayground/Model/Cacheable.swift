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
    
    
    func merge(with other: Self)
}


extension Cacheable {
    func update<V>(keypath: ReferenceWritableKeyPath<Self, V>, value: V) async {
        await CanvasService.shared.repository.update(model: self, keypath: keypath, value: value)
    }
}
