//
//  Cacheable.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 11/1/24.
//

import SwiftData
import Foundation

protocol Cacheable: Codable, Hashable, Equatable {
    associatedtype CachedDTO: DTO
    associatedtype ID: Hashable

    var id: ID? { get }
    static var tag: String { get }
    
    func toDTO() throws -> CachedDTO
}

protocol DTO: PersistentModel {
    associatedtype Model: Cacheable

    var id: String { get }
    
    func toModel() throws -> Model
}
// MARK: Canvas-derived Data
