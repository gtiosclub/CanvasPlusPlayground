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
     - Parameters:
        - request: the desired API query for a **collection** of models.
        - descriptor: an optimized filter to be performed in the query.
        - onCacheReceive: a closure for early execution when cached version is received - if any.
     - Returns: An array of models concerning the desired query.
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
	
	
	@MainActor
	func loadFirstThenSync<Request: CacheableAPIRequest>(
		_ request: Request,
		onCacheReceive: @escaping ([Request.PersistedModel]?) -> Void,
		onSyncComplete: @escaping ([Request.PersistedModel]?) -> Void,
		loadingMethod: LoadingMethod<Request> = .all(onNewPage: { _ in })
	) async throws {
		guard let repository else {
			onCacheReceive(nil)
			onSyncComplete(nil)
			return
		}

		let cached = try await request.load(
			from: repository,
			loadingMethod: loadingMethod
		)
		
		onCacheReceive(cached)
		Task {
			do {
				let freshData = try await request.syncWithAPI(
					to: repository,
					loadingMethod: loadingMethod
				)
				onSyncComplete(freshData)
			} catch {
				// It's good practice to log errors from the background sync.
				LoggerService.main.error("Background sync failed for \(String(describing: request)): \(error.localizedDescription)")
				// Optionally, you can call the completion handler with nil or the cached value again.
				onSyncComplete(cached)
			}
		}
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
