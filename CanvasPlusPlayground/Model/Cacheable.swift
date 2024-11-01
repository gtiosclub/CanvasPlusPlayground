//
//  Cacheable.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 11/1/24.
//

import SwiftData

protocol Cacheable: Codable, Hashable, Equatable {
    associatedtype CachedDTO: DTO
    
    func toDTO() throws -> CachedDTO
}

protocol DTO: PersistentModel {
    associatedtype Model: Cacheable

    var id: ObjectIdentifier { get }
    
    func toModel() throws -> Model
}


