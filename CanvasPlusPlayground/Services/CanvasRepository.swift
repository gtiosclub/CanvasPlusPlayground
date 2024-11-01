//
//  CanvasRepository.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 11/1/24.
//

import SwiftData
import SwiftUI

struct CanvasRepository {
    
    private let modelContainer: ModelContainer
    
    init() {
        self.modelContainer = try! ModelContainer(for:
            CourseDTO.self
        ) // Add cacheable DTOs here
    }
    
    func save<T>(_ item: T) async throws where T : Cacheable {
        let DTO = try item.toDTO()
        
        try await MainActor.run {
            modelContainer.mainContext.insert(DTO)
            
            try modelContainer.mainContext.save()
        }
        
    }
    
    func get<T>(id: PersistentIdentifier) async throws -> T? where T : Cacheable {
        try await MainActor.run {
            let req = FetchDescriptor<T.CachedDTO>(predicate: #Predicate { item in
                item.id == id
            })
            let DTOs = try modelContainer.mainContext.fetch(req)
            
            // Make sure model exists.
            guard DTOs.count > 0 else {
                return nil
            }
            // Uncast it from DTO representation (into Model).
            guard let model = try DTOs[0].toModel() as? T else {
                print("Could not convert model with id \(id) of type \(T.self)")
                throw CacheError.decodingError
            }
            return model
        }
    }
}

enum CacheError: Error {
    case encodingError, decodingError
}
