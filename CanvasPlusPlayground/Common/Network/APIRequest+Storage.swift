//
//  APIRequest+Storage.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/21/24.
//

import Foundation
import SwiftData

extension CacheableAPIRequest {
    fileprivate var loadDescriptor: FetchDescriptor<PersistedModel> {
        // Join custom predicate with id-filtering predicate

        var cacheDescriptor = FetchDescriptor<PersistedModel>()

        let customPred = self.customPredicate
        let idPred = self.idPredicate
        cacheDescriptor.predicate = #Predicate {
            customPred.evaluate($0) && idPred.evaluate($0)
        }
        return cacheDescriptor
    }
    
    /// Only loads from storage, doesn't make a network call
    func load(from repository: CanvasRepository) async throws -> [PersistedModel]? {
                
        // Get cached data for this type then filter to only get models related to `request`
        let cached: [PersistedModel]? = try await repository.get(descriptor: loadDescriptor)
        
        return cached
    }
    
    /// Number of occurences of models related to request
    func loadCount(from repository: CanvasRepository) async throws -> Int {
        return try await repository.count(descriptor: loadDescriptor)
    }
}
