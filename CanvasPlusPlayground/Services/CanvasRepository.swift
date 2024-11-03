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
            Course.self
        ) // TODO: Add cacheable DTOs here
    }
    
    func save<T>(_ item: T) async throws where T : Cacheable {
        try await MainActor.run {
            modelContainer.mainContext.insert(item)
            
            try modelContainer.mainContext.save()
        }
    }
    
    func getSingle<T>(with id: T.ID) async throws -> T? where T : Cacheable {
        let descriptor = FetchDescriptor<T>(predicate: #Predicate { item in
            true //id == $0.id
        })
        
        let models: [T] = try await get<T>(descriptor: descriptor)
        
        // Make sure model exists.
        if models.count > 0 {
            return models[0]
        } else { return nil }
    }
    
    /// Gets all data based on type. e.g. all Course objects to get all courses
    func get<T>(with predicate: Predicate<T>) async throws -> [T]? where T : Cacheable {
        let descriptor = FetchDescriptor<T>(predicate: predicate)
        
        let models: [T] = try await get<T>(descriptor: descriptor)
        
        // Make sure model exists.
        if models.count > 0 {
            return models
        } else { return nil }
    }
    
    /// Gets all data based on type. e.g. all Course objects to get all courses
    func get<T>() async throws -> [T]? where T : Cacheable {
        let predicate = #Predicate<T> { _ in true }
        
        return try await get(with: predicate)
    }
    
    
    private func get<T>(descriptor: FetchDescriptor<T>) async throws -> [T] where T : Cacheable {
        
        let models = try await MainActor.run {
            let models = try modelContainer.mainContext.fetch(descriptor)
            return models
        }
        
        return models
    }
}

enum CacheError: Error {
    case encodingError, decodingError
}
