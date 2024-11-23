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
            Course.self, Announcement.self, Enrollment.self
        ) // TODO: Add cacheable models here
    }
    
    @MainActor
    func insert<T>(_ item: T) where T : Cacheable {
        modelContainer.mainContext.insert(item)
    }
    
    /// Gets all data based on type. e.g. all Course objects to get all courses
    @MainActor
    func get<T>(
        descriptor: FetchDescriptor<T>
    ) throws -> [T]? where T : Cacheable {
        
        let models: [T] = try modelContainer.mainContext.fetch(descriptor)
        
        // Make sure model exists.
        if models.count > 0 {
            return models
        } else { return nil }
    }
    
    @MainActor
    func count<T>(
        descriptor: FetchDescriptor<T>
    ) throws -> Int where T : Cacheable {
        
        return try modelContainer.mainContext.fetchCount(descriptor)
    }
    
    @MainActor
    func delete(_ model: any PersistentModel) {
        modelContainer.mainContext.delete(model)
    }
    
    /// Push SwiftData changes to disk.
    func flush() {
        Task { @MainActor in
            do {
                try self.modelContainer.mainContext.save()
            } catch {
                print("Trouble saving to cache")
            }
        }
    }

}

enum CacheError: Error {
    case encodingError, decodingError
}
