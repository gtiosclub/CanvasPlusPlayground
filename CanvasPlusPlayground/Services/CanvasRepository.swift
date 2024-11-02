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
        ) // TODO: Add cacheable DTOs here
    }
    
    func save<T>(_ item: T) async throws where T : Cacheable {
        let DTO = try item.toDTO()
        
        try await MainActor.run {
            modelContainer.mainContext.insert(DTO)
            
            try modelContainer.mainContext.save()
        }
        
    }
    
    func get<T>(id: T.ID) async throws -> T? where T : Cacheable {
        let id = String(describing: id)
        let descriptor = FetchDescriptor<T.CachedDTO>(predicate: #Predicate { (item) in
            item.id == id 
        })
        
        let models: [T] = try await get<T>(descriptor: descriptor)
        
        // Make sure model exists.
        if models.count > 0 {
            return models[0]
        } else { return nil }
    }
    
    /// Gets all data based on type. e.g. all Course objects to get all courses
    func get<T>() async throws -> [T]? where T : Cacheable {
        let tag = T.tag
        let descriptor = FetchDescriptor<T.CachedDTO>()
        
        let models: [T] = try await get<T>(descriptor: descriptor)
        
        // Make sure model exists.
        if models.count > 0 {
            return models
        } else { return nil }
    }
    
    private func get<T>(descriptor: FetchDescriptor<T.CachedDTO>) async throws -> [T] where T : Cacheable {
        let models = try await MainActor.run {
            let DTOs = try modelContainer.mainContext.fetch(descriptor)
            
            // Uncast it from DTO representation (into Model).
            guard let models = try DTOs.map({ try $0.toModel() }) as? [T] else {
                print("Could not convert to model of type \(T.self)")
                throw CacheError.decodingError
            }
            return models
        }
        
        return models
    }
}

enum CacheError: Error {
    case encodingError, decodingError
}
