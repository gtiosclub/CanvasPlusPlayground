//
//  Cacheable.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 11/1/24.
//

import SwiftData
import Foundation

protocol Cacheable: Codable, Sendable, PersistentModel {
    associatedtype ServerID: Hashable
    var id: String { get }
    
    func merge(with other: Self)
}


/**
 To define new attribute in existing models:
 1. Define attribute in model. 
 2. In definitions, provide a default value to avoid corrupting existing storage.
 */
