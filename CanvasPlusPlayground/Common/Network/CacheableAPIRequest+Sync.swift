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

     **Blocking behavior:** This method blocks until the network request completes, then returns the fresh data.

     - Parameters:
        - repository: The storage repository to load from and sync to.
        - onCacheReceive: A closure called immediately with cached data (if any) before network request starts.
        - loadingMethod: The loading strategy (all pages, single page, etc.).
     - Returns: An array of fresh models from the network.

     - Note: Use this when you need the fresh data synchronously. For faster perceived performance where
             the UI should update immediately with cached data while fresh data loads in the background,
             use `loadFirstThenSync` instead.
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

    /**
     Load cached data immediately, then sync with API in the background without blocking.

     **Non-blocking behavior:** This method returns immediately after loading and delivering cached data.
     The network sync happens in a background task, and fresh data is delivered via the completion callback.

     **Key Difference from `loadAndSync`:**
     - `loadAndSync`: **Blocks** until network completes → slower perceived load, but you get fresh data as return value
     - `loadFirstThenSync`: **Non-blocking** → faster perceived load, UI updates immediately with cache, then updates again with fresh data

     **Performance:**
     This method is optimized to avoid redundant cache queries by passing the already-loaded cache
     to the sync operation, unlike naive implementations that would reload the cache.

     - Parameters:
        - repository: The storage repository to load from and sync to.
        - onCacheReceive: Called immediately with cached data (if any). Use this to update UI instantly.
        - onSyncComplete: Called when network sync completes with fresh data. If sync fails, cached data is returned.
        - loadingMethod: The loading strategy (all pages, single page, etc.).

     - Note: Ideal for widgets and views where showing stale data quickly is better UX than waiting for fresh data.
     **/
    func loadFirstThenSync(
        to repository: CanvasRepository,
        onCacheReceive: @escaping ([PersistedModel]?) -> Void,
        onSyncComplete: @escaping ([PersistedModel]?) -> Void,
        loadingMethod: LoadingMethod<Self> = .all(onNewPage: { _ in })
    ) async {
        let cached: [PersistedModel]? = (try? await load(
            from: repository,
            loadingMethod: loadingMethod
        ))

        onCacheReceive(cached)

        // Sync in background without blocking
        Task {
            do {
                let freshData = try await syncWithAPI(
                    to: repository,
                    using: cached ?? [],
                    loadingMethod: loadingMethod
                )
                onSyncComplete(freshData)
            } catch {
                // Sync failed, return cached data
                onSyncComplete(cached)
            }
        }
    }
}
