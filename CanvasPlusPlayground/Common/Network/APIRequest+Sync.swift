//
//  APIRequest+Sync.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/21/24.
//

import Foundation

extension CacheableAPIRequest {
    @discardableResult
    func syncWithAPI(
        to repository: CanvasRepository,
        onNewBatch: ([PersistedModel]) -> Void = { _ in }
    ) async throws -> [PersistedModel] {
        let cached = try await load(from: repository) ?? []
        
        return try await syncWithAPI(
            to: repository,
            using: cached,
            onNewBatch: onNewBatch
        )
    }
    
    // TODO: use predicate filters whenever
    private func syncWithAPI(
        to repository: CanvasRepository,
        using cache: [PersistedModel],
        onNewBatch: ([PersistedModel]) -> Void
    ) async throws -> [PersistedModel] {
        
        let cacheLookup = Dictionary(uniqueKeysWithValues: cache.map { ($0.id, $0) } )
        
        let updateStorage: ([PersistedModel]) async -> [PersistedModel] = { newModels in
            // New batch received
                        
            var latest = newModels
            // Merge fetched model into cached model OR cache fetched model as new.
            for (i, latestModel) in latest.enumerated() {
                if let matchedCached = cacheLookup[latestModel.id] {
                    await repository.merge(other: latestModel, into: matchedCached)
                    latest[i] = matchedCached
                } else {
                    await repository.insert(latestModel)
                }
            }
            
            
            let writeKeyPath = self.requestIdKey.writableKeyPath
            if let writeKeyPath {
                // Store the request / parent id in each model so that we can recall all models when repeating a request
                for model in latest {
                    await model.update(keypath: writeKeyPath, value: self.requestId)
                }
            }
            
            
            
            return latest
        }
        
        // Fetch newest version from API, then filter as desired by caller.
        var latest: [PersistedModel] = try await {
            
            // Adjust `fetch` generic parameter based on whether request is for a collection.
            let fetched: [PersistedModel]
            if QueryResult.self is any Collection.Type {
                fetched = try await fetch(onNewPage: { batch in
                    let batchAsModel = batch.map { $0.createModel() }
                    let transformed = await updateStorage(batchAsModel)
                    
                    onNewBatch(transformed)
                }).map { $0.createModel() }
            } else {
                let responseAsModel = try await fetch().map { $0.createModel() }
                fetched = await updateStorage(responseAsModel)
            }
            
            return fetched
        }()
        
        // User storage version of model
        for (i, latestModel) in latest.enumerated() {
            if let matchedCached = cacheLookup[latestModel.id] {
                latest[i] = matchedCached
            }
        }
                
        return latest
    }
    
    /**
     Fetch a collection of data from the Canvas API. Also provides cached version via closure (if any). Allows filtering.
     - Parameters:
        - request: the desired API query for a **collection** of models.
        - descriptor: an optimized filter to be performed in the query.
        - onCacheReceive: a closure for early execution when cached version is received - if any.
        - onNewBatch: if the request involves pagination, this closure will be executed upon arrival of each batch
     - Returns: An array of models concerning the desired query.
     **/
    func loadAndSync(
        to repository: CanvasRepository,
        onCacheReceive: ([PersistedModel]?) -> Void = { _ in },
        onNewBatch: ([PersistedModel]) -> Void = { _ in }
    ) async throws -> [PersistedModel] {
        
        let cached: [PersistedModel]? = try await load(from: repository)
        onCacheReceive(cached) // Share cached version with caller.
            
        let latest = try await syncWithAPI(to: repository, using: cached ?? [], onNewBatch: onNewBatch)
        
        return latest
    }
}
