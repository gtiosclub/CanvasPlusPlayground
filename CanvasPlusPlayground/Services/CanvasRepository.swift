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
            Course.self
        ) // TODO: Add cacheable models here
    }
    
    func insert<T>(_ item: T) async throws where T : Cacheable {
        try await MainActor.run {
            modelContainer.mainContext.insert(item)
            
            try modelContainer.mainContext.save()
        }
    }
    
    func getSingle<T>(with id: T.ServerID) async throws -> T? where T : Cacheable {
        let id = String(describing: id)
        let descriptor = FetchDescriptor<T>(predicate: #Predicate { model in
            model.id == id
        })
        
        let models: [T] = try await get<T>(descriptor: descriptor)
        
        // Make sure model exists.
        if models.count > 0 {
            return models[0]
        } else { return nil }
    }
    
    /// Gets all data based on type. e.g. all Course objects to get all courses
    func get<T, V: Equatable>(
        with keypath: KeyPath<T,V>? = nil,
        equals value: V? = nil
    ) async throws -> [T]? where T : Cacheable {
        
        let descriptor = {
            if let keypath, let value {
                let pred = Foundation.Predicate<T> { model in
                    PredicateExpressions.build_Equal(
                        lhs: PredicateExpressions.KeyPath(root: model, keyPath: keypath),
                        rhs: PredicateExpressions.Value(value)
                    ) as! any StandardPredicateExpression<Bool>
                }
                return FetchDescriptor<T>(predicate: pred)
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
    
    func update() async {
        await MainActor.run {
            try? modelContainer.mainContext.save()
        }
    }
}

enum CacheError: Error {
    case encodingError, decodingError
}
