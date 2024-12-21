//
//  CanvasService.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/14/24.
//

import Foundation
import SwiftData

struct CanvasService {
    static var shared = CanvasService()
    
    let repository: CanvasRepository
    
    init()  {
        var repo: CanvasRepository?
        let semaphore = DispatchSemaphore(value: 0)

        Task.detached {
            let initializedRepo = CanvasRepository()
            repo = initializedRepo
            semaphore.signal()
        }

        semaphore.wait()

        guard let repo else {
            preconditionFailure("Error initializing CanvasRepository.")
        }
        self.repository = repo
    }
    
    /// Only loads from storage, doesn't make a network call
    func load<Request: CacheableAPIRequest>(_ request: Request) async throws -> [Request.Subject]? {
                
        // Get cached data for this type then filter to only get models related to `request`
        let cached: [Request.Subject]? = try await request.load(from: repository)
        
        return cached
    }
    
    /// Number of occurences of models related to request
    func loadCount<Request: CacheableAPIRequest>(_ request: Request) async throws -> Int {
        return try await request.loadCount(from: repository)
    }
    
    @discardableResult
    func syncWithAPI<Request: CacheableAPIRequest>(
        _ request: Request,
        onNewBatch: ([Request.Subject]) -> Void = { _ in }
    ) async throws -> [Request.Subject] {
        // Call syncWithAPI for cacheable requests
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
        
        let cached: [Request.Subject]? = try await request.load(from: repository)
        onCacheReceive(cached) // Share cached version with caller.
            
        let latest = try await request.syncWithAPI(to: repository, onNewBatch: onNewBatch)
        
        return latest
    }
    
    // MARK: Network Requests
    
    func fetchResponse<Request: APIRequest>(_ request: Request) async throws -> (data: Data, response: URLResponse) {
        return try await request.fetchResponse()
    }
    
    // MARK: Repository actions
    
    func clearStorage() {
        repository.modelContainer.deleteAllData()
    }
    
    private func filterByDescriptor<T>(
        _ descriptor: FetchDescriptor<T>, models: [T]
    ) throws -> [T] where T: Cacheable {
        let predicate = descriptor.predicate ?? #Predicate { _ in true }
        let sorters = descriptor.sortBy
        
        let filteredModels = try models.filter(predicate).sorted { a, b in
            for sorter in sorters {
                let comparison = sorter.compare(a, b)
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
