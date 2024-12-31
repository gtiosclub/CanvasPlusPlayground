//
//  CanvasService.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/14/24.
//

import Foundation
import SwiftData

class CanvasService {
    static var shared = CanvasService()

    var repository: CanvasRepository?

    func activate() {
        Task.detached { [weak self] in
            let repo = CanvasRepository()
            self?.repository = repo
        }
    }

    /// Only loads from storage, doesn't make a network call
    func load<Request: CacheableAPIRequest>(_ request: Request) async throws -> [Request.Subject]? {
        guard let repository else { return nil }

        // Get cached data for this type then filter to only get models related to `request`
        let cached: [Request.Subject]? = try await request.load(from: repository)

        return cached
    }

    /// Number of occurences of models related to request
    func loadCount<Request: CacheableAPIRequest>(_ request: Request) async throws -> Int {
        guard let repository else { return 0 }

        return try await request.loadCount(from: repository)
    }

    @discardableResult
    func syncWithAPI<Request: CacheableAPIRequest>(
        _ request: Request,
        onNewBatch: ([Request.Subject]) -> Void = { _ in }
    ) async throws -> [Request.Subject] {
        guard let repository else { return [] }

        // Call for cacheable requests
        let result = try await request.syncWithAPI(to: repository, onNewBatch: onNewBatch)
        print("Synced: \(result)")
        return result
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
    func loadAndSync<Request: CacheableAPIRequest>(
        _ request: Request,
        onCacheReceive: ([Request.Subject]?) -> Void = { _ in },
        onNewBatch: ([Request.Subject]) -> Void = { _ in }
    ) async throws -> [Request.Subject] {
        guard let repository else { return [] }

        let cached: [Request.Subject]? = try await request.load(from: repository)
        onCacheReceive(cached) // Share cached version with caller.

        let latest = try await request.syncWithAPI(to: repository, onNewBatch: onNewBatch)

        return latest
    }

    // MARK: Network Requests

    func fetchResponse<Request: APIRequest>(_ request: Request) async throws -> (data: Data, response: URLResponse) {
        return try await request.fetchResponse()
    }

    func fetch<Request: APIRequest>(_ request: Request) async throws -> [Request.Subject] {
        return try await request.fetch()
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

        let filteredModels = try models.filter(predicate).sorted { modelA, modelB in
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

        return filteredModels
    }
}
