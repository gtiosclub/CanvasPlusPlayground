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
        
    @MainActor
    private func get<T>(descriptor: FetchDescriptor<T>) throws -> [T] where T : Cacheable {
        
        let models = try modelContainer.mainContext.fetch(descriptor)
        return models
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
