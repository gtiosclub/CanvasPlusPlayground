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
    
    //let modelContainer: ModelContainer
    
    init() {
        self.modelContainer = try! ModelContainer(for:
            Course.self, Announcement.self, Enrollment.self
        ) // TODO: Add cacheable models here
        let context = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    }
    
    //@MainActor
    func insert<T>(_ item: T) throws where T : Cacheable {
        modelContext.insert(item)
    }
    
    /// Gets all data based on type. e.g. all Course objects to get all courses
    func get<T, V: Equatable>(
        condition: LookupCondition<T, V>? = nil
    ) throws -> [T]? where T : Cacheable {
        
        let descriptor = {
            var descriptor = FetchDescriptor<T>(
                predicate: condition?.expression()
            )
            
            return descriptor
        }()
        
        let models: [T] = try get<T>(descriptor: descriptor)
        
        // Make sure model exists.
        if models.count > 0 {
            return models
        } else { return nil }
    }
        
    //@MainActor
    private func get<T>(descriptor: FetchDescriptor<T>) throws -> [T] where T : Cacheable {
        
        let models = try modelContext.fetch(descriptor)
        return models
    }
    
    //@MainActor
    func delete(_ model: any PersistentModel) {
        modelContext.delete(model)
    }
    
    /// Push SwiftData changes to disk.
    func flush() {
        do {
            try self.modelContext.save()
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
