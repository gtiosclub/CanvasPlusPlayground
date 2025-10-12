//
//  CanvasService.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/14/24.
//

import Foundation
import SwiftData

class CanvasService {
    
    public static let canvasDomain = "gatech.instructure.com/"
    public static let canvasWebURL = "https://\(canvasDomain)"
    public static let canvasSystemURL = "canvas-courses://"
    
    static var shared = CanvasService()

    var repository: CanvasRepository?

    @MainActor func setupStorage() {
        let repo = CanvasRepository()
        self.repository = repo
    }

    /// Only loads from storage, doesn't make a network call
    @MainActor
    func load<Request: CacheableAPIRequest>(
        _ request: Request,
        loadingMethod: LoadingMethod<Request> = .all(onNewPage: { _ in })
    ) async throws -> [Request.PersistedModel]? {
        guard let repository else { return nil }

        // Get cached data for this type then filter to only get models related to `request`
        return try await request.load(
            from: repository,
            loadingMethod: loadingMethod
        ) as [Request.PersistedModel]?
    }

    /// Number of occurences of models related to request
    @MainActor
    func loadCount<Request: CacheableAPIRequest>(_ request: Request) async throws -> Int {
        guard let repository else { return 0 }

        return try await request.loadCount(from: repository)
    }

    @discardableResult
    @MainActor
    func syncWithAPI<Request: CacheableAPIRequest>(
        _ request: Request,
        loadingMethod: LoadingMethod<Request> = .all(onNewPage: { _ in })
    ) async throws -> [Request.PersistedModel] {
        guard let repository else { return [] }

        // Call for cacheable requests
        return try await request.syncWithAPI(
            to: repository,
            loadingMethod: loadingMethod
        )
    }

    /**
     Fetch a collection of data from the Canvas API. Also provides cached version via closure (if any). Allows filtering.

     **Blocking behavior:** This method blocks until the network request completes, then returns the fresh data.

     - Parameters:
        - request: the desired API query for a **collection** of models.
        - onCacheReceive: a closure for early execution when cached version is received - if any.
        - loadingMethod: the loading strategy (all pages, single page, etc.).
     - Returns: An array of fresh models from the network.

     - Note: Use this when you need the fresh data synchronously. For faster perceived performance,
             use `loadFirstThenSync` instead.
     **/
    @discardableResult
    @MainActor
    func loadAndSync<Request: CacheableAPIRequest>(
        _ request: Request,
        onCacheReceive: ([Request.PersistedModel]?) -> Void = { _ in },
        loadingMethod: LoadingMethod<Request> = .all(onNewPage: { _ in })
    ) async throws -> [Request.PersistedModel] {
        guard let repository else { return [] }

        let cached: [Request.PersistedModel]? = try await request.load(
            from: repository,
            loadingMethod: loadingMethod
        )
        onCacheReceive(cached) // Share cached version with caller.

        return try await request.syncWithAPI(
            to: repository,
            loadingMethod: loadingMethod
        )
    }

    /**
     Load cached data immediately, then sync with API in the background without blocking.

     **Non-blocking behavior:** This method returns immediately after loading cached data.
     Network sync happens in background, delivering fresh data via completion callback.

     **Key Difference from `loadAndSync`:**
     - `loadAndSync`: **Blocks** until network completes → slower perceived load
     - `loadFirstThenSync`: **Non-blocking** → faster perceived load, shows cache instantly

     **Performance Benefits:**
     - Widget/view displays cached data within milliseconds
     - Network fetch happens without blocking the UI
     - Optimized to avoid redundant cache queries

     - Parameters:
        - request: the desired API query for a **collection** of models.
        - onCacheReceive: Called immediately with cached data (if any). Update UI here for instant display.
        - onSyncComplete: Called when network sync completes with fresh data. Update UI here with latest data.
        - loadingMethod: the loading strategy (all pages, single page, etc.).

     - Note: Ideal for widgets and views where showing stale data quickly provides better UX.
     **/
    @MainActor
    func loadFirstThenSync<Request: CacheableAPIRequest>(
        _ request: Request,
        onCacheReceive: @escaping ([Request.PersistedModel]?) -> Void,
        onSyncComplete: @escaping ([Request.PersistedModel]?) -> Void,
        loadingMethod: LoadingMethod<Request> = .all(onNewPage: { _ in })
    ) async {
        guard let repository else {
            onCacheReceive(nil)
            onSyncComplete(nil)
            return
        }

        await request.loadFirstThenSync(
            to: repository,
            onCacheReceive: onCacheReceive,
            onSyncComplete: onSyncComplete,
            loadingMethod: loadingMethod
        )
    }

    // MARK: Network Requests

    func fetchResponse<Request: APIRequest>(_ request: Request, at page: Int? = nil) async throws -> (data: Data, url: URLResponse) {
        try await request.fetchResponse(at: page)
    }

    @discardableResult
    func fetch<Request: APIRequest>(
        _ request: Request,
        loadingMethod: LoadingMethod<Request> = .all(onNewPage: { _ in })
    ) async throws -> [Request.Subject] {
        try await request.fetch(loadingMethod: loadingMethod)
    }

    // MARK: Repository actions

    func clearStorage() {
        repository?.modelContainer.deleteAllData()
    }

    private func filterByDescriptor<T>(
        _ descriptor: FetchDescriptor<T>, models: [T]
    ) throws -> [T] where T: Cacheable {
        let predicate = descriptor.predicate ?? #Predicate { _ in true }
        let sorters = descriptor.sortBy

        return try models.filter(predicate).sorted { modelA, modelB in
            for sorter in sorters {
                let comparison = sorter.compare(modelA, modelB)
                switch sorter.order {
                case .forward:
                    if comparison == .orderedAscending { return true }
                    if comparison == .orderedDescending { return false }
                case .reverse:
                    if comparison == .orderedDescending { return true }
                    if comparison == .orderedAscending { return false }
                }
            }
            return false
        }
    }
}
