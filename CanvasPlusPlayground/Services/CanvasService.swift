//
//  CanvasService.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/14/24.
//

import Foundation

struct CanvasService {
    static let shared = CanvasService()
    
    let repository = CanvasRepository()
    
    func fetchResponse(_ request: CanvasRequest) async throws -> (data: Data, response: URLResponse) {
        guard let url = request.url else { throw NetworkError.invalidURL(msg: request.path) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NetworkError.fetchFailed(msg: response.description)
            }
            
            return (data, response)
        } catch {
            throw NetworkError.fetchFailed(msg: error.localizedDescription)
        }
    }
    
    /// To fetch a single cacheable object from the Canvas API, also provides cached version via closure (if any).
    func defaultAndFetchSingle<T: Cacheable>(
        _ request: CanvasRequest,
        onCacheReceive: (T?) -> Void = { _ in }
    ) async throws -> T {
        
        // If subject is cached
        if let id = request.id as? T.ServerID, let cached: T = try await repository.getSingle(with: id) {
            onCacheReceive(cached)
            
            let latest: T = try await fetch(request)
            cached.merge(with: latest)
            
            try await insert(model: cached)
            return latest
        } else {
            onCacheReceive(nil)
            let latest: T = try await fetch(request)
            
            try await insert(model: latest)
            return latest
        }
    }
    
    /// To fetch a collection of data from the Canvas API, also provides cached version via closure (if any). Allows for filtering.
    func defaultAndFetch<T: Codable, V: Equatable>(
        _ request: CanvasRequest,
        condition: LookupCondition<T.Element, V>?,
        onCacheReceive: ([T.Element]?) -> Void
    ) async throws -> T where T : Collection, T.Element : Cacheable {
        // If contents of subject are cached
        if let cached: [T.Element] = try await repository.get(condition: condition) {
            onCacheReceive(cached)
            
            let latest: T = try await fetch(request)
            let cachedById = Dictionary(uniqueKeysWithValues: cached.map { ($0.id, $0) })

            // If model exists in cache, merge latest with it. Otherwise, insert it as new.
            await withTaskGroup(of: Void.self) { group in
                for latestModel in latest {
                    if let matchedCached = cachedById[latestModel.id] {
                        matchedCached.merge(with: latestModel)
                    } else {
                        try? await repository.insert(latestModel)
                    }
                }
            }
            
            
            return cached as! T
        } else {
            onCacheReceive(nil)
            let latest: T = try await fetch(request)
            
            try await insert(model: latest)
            return [] as! T
        }
        
    }
    
    /// To fetch a collection of data from the Canvas API, also provides cached version via closure (if any).
    func defaultAndFetch<T: Codable>(
        _ request: CanvasRequest,
        onCacheReceive: ([T.Element]?) -> Void
    ) async throws -> T where T : Collection, T.Element : Cacheable {
        return try await defaultAndFetch<T, String>(request, condition: nil as LookupCondition<T.Element, String>?, onCacheReceive: onCacheReceive)
    }
    
    /// To fetch data from the Canvas API, only!
    func fetch<T: Codable>(_ request: CanvasRequest) async throws -> T {
        
        // API fetch
        let (data, _) = try await CanvasService.shared.fetchResponse(request)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        // TODO: each model should have its own decoder
        
        do {
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch {
            throw NetworkError.failedToDecode(msg: error.localizedDescription)
        }
    }
    
    /// Push SwiftData changes to disk.
    func saveAll() {
        Task {
            await repository.saveAll()
        }
    }
    
    private func insert(model: Any) async throws {
        // if data itself is cacheable -> save, if data is an array of cacheables -> wrap-around
        if let toCache = model as? (any Cacheable) {
            try await repository.insert(toCache)
        } else if let arrayOfCacheables = model as? [any Cacheable] {
            for cacheable in arrayOfCacheables {
                try await repository.insert(cacheable)
            }
        }
    }
}

enum NetworkError: Error {
    case failedToDecode(msg: String), fetchFailed(msg: String), invalidURL(msg: String)
}
