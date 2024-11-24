//
//  CanvasRepository.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 11/1/24.
//

import SwiftData
import SwiftUI

@ModelActor
actor CanvasRepository {
        
    init() {
        self.modelContainer = try! ModelContainer(for:
            Course.self, Announcement.self, Enrollment.self
        ) // TODO: Add cacheable models here
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = true
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    }
    
    func insert<T>(_ item: T) where T : Cacheable {
        modelContext.insert(item)
    }
    
    /// Gets all data based on type. e.g. all Course objects to get all courses
    func get<T>(
        descriptor: FetchDescriptor<T>
    ) throws -> [T]? where T : Cacheable {
        
        let models: [T] = try modelContext.fetch(descriptor)
        
        // Make sure model exists.
        if models.count > 0 {
            return models
        } else { return nil }
    }
    
    func count<T>(
        descriptor: FetchDescriptor<T>
    ) throws -> Int where T : Cacheable {
        
        return try modelContext.fetchCount(descriptor)
    }
    
    func delete(_ model: any PersistentModel) {
        modelContext.delete(model)
    }
    
    /// Push SwiftData changes to disk.
    func flush() {
        do {
            try modelContext.save()
        } catch {
            print("Trouble saving to cache")
        }
    }
    
    func update<T, V>(model: T, keypath: ReferenceWritableKeyPath<T, V>, value: V) where T : Cacheable {
        model[keyPath: keypath] = value
    }

    func merge<T>(other: T, into model: T) where T : Cacheable {
        model.merge(with: other)
    }

    func setAutosave(_ enabled: Bool) async {
        self.modelContext.autosaveEnabled = enabled
    }

}

enum CacheError: Error {
    case encodingError, decodingError
}
