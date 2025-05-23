//
//  CacheableAPIRequest+Sync.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/21/24.
//

import Foundation

extension CacheableAPIRequest {
    @discardableResult
    @MainActor
    func syncWithAPI(
        to repository: CanvasRepository,
        loadingMethod: LoadingMethod<Self> = .all(onNewPage: { _ in })
    ) async throws -> [PersistedModel] {
        let cached = try await load(from: repository, loadingMethod: .all(onNewPage: { _ in })) ?? []

        return try await syncWithAPI(
            to: repository,
            using: cached,
            loadingMethod: loadingMethod
        )
    }

    @MainActor
    private func syncWithAPI(
        to repository: CanvasRepository,
        using cache: [PersistedModel],
        loadingMethod: LoadingMethod<Self>
    ) async throws -> [PersistedModel] {
        let cacheLookup = Dictionary(uniqueKeysWithValues: Set(cache).map { ($0.id, $0) })

        let updateStorage: ([PersistedModel]) async -> [PersistedModel] = { newModels in
            // New batch received

            var latest = newModels
            // Merge fetched model into cached model OR cache fetched model as new.
            for (index, latestModel) in latest.enumerated() {
                if let matchedCached = cacheLookup[latestModel.id] {
                    repository.merge(other: latestModel, into: matchedCached)
                    latest[index] = matchedCached
                } else {
                    repository.insert(latestModel)
                }
            }

            let writeKeyPath = self.requestIdKey.writableKeyPath
            if let writeKeyPath {
                // Store the request / parent id in each model so that we can recall all models when repeating a request
                for model in latest {
                    model[keyPath: writeKeyPath] = self.requestId
                }
            }

            return latest
        }

        // Fetch newest version from API, then filter as desired by caller.
        var latest: [PersistedModel] = try await {
            // Adjust `fetch` generic parameter based on whether request is for a collection.
            var fetched: [PersistedModel] = []
            if QueryResult.self is any Collection.Type {
                if case let .all(onNewPage) = loadingMethod {
                    _ = try await fetch(
                        loadingMethod: loadingMethod,
                        onNewPage: { batch in
                            let batchAsModel = batch.map { $0.createModel() }
                            let transformed = await updateStorage(batchAsModel)

                            fetched += transformed
                            onNewPage(transformed)
                        }
                    )
                } else {
                    let raw = try await fetch(loadingMethod: loadingMethod)
                    fetched = await updateStorage(raw.map { $0.createModel() })
                }
            } else {
                let responseAsModel = try await fetch(loadingMethod: loadingMethod).map {
                    $0.createModel()
                }
                fetched = await updateStorage(responseAsModel)
            }

            return fetched
        }()

        // User storage version of model
        for (index, latestModel) in latest.enumerated() {
            if let matchedCached = cacheLookup[latestModel.id] {
                latest[index] = matchedCached
            }
        }

        try repository.modelContext.save()

        return latest
    }

    /**
     Fetch a collection of data from the Canvas API. Also provides cached version via closure (if any). Allows filtering.
     - Parameters:
        - request: the desired API query for a **collection** of models.
        - descriptor: an optimized filter to be performed in the query.
        - onCacheReceive: a closure for early execution when cached version is received - if any.
     - Returns: An array of models concerning the desired query.
     **/
    func loadAndSync(
        to repository: CanvasRepository,
        onCacheReceive: ([PersistedModel]?) -> Void = { _ in },
        loadingMethod: LoadingMethod<Self> = .all(onNewPage: { _ in })
    ) async throws -> [PersistedModel] {
        let cached: [PersistedModel]? = try await load(
            from: repository,
            loadingMethod: loadingMethod
        )
        onCacheReceive(cached) // Share cached version with caller.

        return try await syncWithAPI(
            to: repository,
            using: cached ?? [],
            loadingMethod: loadingMethod
        )
    }
}
