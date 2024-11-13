//
//  CanvasRepository.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 11/1/24.
//

import SwiftData
import SwiftUI

struct CanvasRepository {
    
    let modelContainer: ModelContainer
    
    init() {
        self.modelContainer = try! ModelContainer(for:
            Course.self, Announcement.self
        ) // TODO: Add cacheable models here
    }
    
    @MainActor
    func insert<T>(_ item: T) async throws where T : Cacheable {
        modelContainer.mainContext.insert(item)
        
        try modelContainer.mainContext.save()
    }
    
    /// Gets all data based on type. e.g. all Course objects to get all courses
    func get<T, V: Equatable>(
        condition: LookupCondition<T, V>?
    ) async throws -> [T]? where T : Cacheable {
        
        let descriptor = {
            if let predicate = condition?.expression() {
                return FetchDescriptor<T>(predicate: predicate)
            } else {
                return FetchDescriptor<T>()
            }
        }()
        
        let models: [T] = try await get<T>(descriptor: descriptor)
        
        // Make sure model exists.
        if models.count > 0 {
            return models
        } else { return nil }
    }
    
    
    private func get<T>(descriptor: FetchDescriptor<T>) async throws -> [T] where T : Cacheable {
        
        let models = try await MainActor.run {
            let models = try modelContainer.mainContext.fetch(descriptor)
            return models
        }
        
        return models
    }
    
    @MainActor
    func delete(_ model: any PersistentModel) {
        modelContainer.mainContext.delete(model)
        try? modelContainer.mainContext.save()
    }
}

enum CacheError: Error {
    case encodingError, decodingError
}
