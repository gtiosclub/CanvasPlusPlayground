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
    
    /*private*/ func fetchResponse(_ request: CanvasRequest) async throws -> (data: Data, response: URLResponse) {
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
    
    
    /**
     Fetch a collection of data from the Canvas API. Also provides cached version via closure (if any). Allows filtering.
     - Parameters:
        - request: the desired API query for a **collection** of models.
        - condition: an optimized filter to be performed in the query.
        - onCacheReceive: a closure for early execution when cached version is received - if any.
     - Returns: An array of models concerning the desired query.
     **/
    func defaultAndFetch<T: Codable & Collection, V: Equatable>(
        _ request: CanvasRequest,
        condition: LookupCondition<T.Element, V>?,
        onCacheReceive: ([T.Element]?) -> Void
    ) async throws -> T where T.Element : Cacheable {
        if !(request.associatedModel == T.self || request.associatedModel == T.Element.self){
            preconditionFailure("Provided generic type T = \(T.self) does not match the expected `associatedModel` type \(request.associatedModel) in request.")
        }
                
        // If contents of subject are cached.
        if let cached: [T.Element] = try await repository.get(condition: condition) {
            onCacheReceive(cached) // Share cached version with caller.
            
            // Fetch newest version from API, then filter as desired by caller.
            let latest: [T.Element] = try await {
                // Adjust `fetch` generic parameter based on whether request is for a collection.
                let fetched: [T.Element]
                if request.associatedModel is any Collection.Type {
                    fetched = try await fetch(request)
                } else {
                    let fetchedItem: T.Element = try await fetch(request)
                    fetched = [fetchedItem]
                }
                
                return fetched.filter { (try? condition?.expression().evaluate($0)) ?? true }
            }()
            
            // Create cache lookup by id
            let cachedById = Dictionary(uniqueKeysWithValues: cached.map { ($0.id, $0) })
            
            // For each fetched model, if fetched model exists in cache, merged fetched model into cached model. Otherwise, cache fetched model as new.
            var final: [T.Element] = []
                
            for latestModel in latest {
                if let matchedCached = cachedById[latestModel.id] {
                    matchedCached.merge(with: latestModel)
                    final.append(matchedCached)
                } else {
                    try? await repository.insert(latestModel)
                    final.append(latestModel)
                }
            }
            
            return final as! T
        } else {
            onCacheReceive(nil) // Inform caller that no cache for request exists.
            
            // Fetch newest version from API, then filter as desired by caller.
            let latest: [T.Element] = try await {
                let fetched: [T.Element]
                if request.associatedModel is any Collection.Type {
                    fetched = try await fetch(request)
                } else {
                    let fetchedItem: T.Element = try await fetch(request)
                    fetched = [fetchedItem]
                }
                
                return fetched.filter { (try? condition?.expression().evaluate($0)) ?? true }
            }()
            
            // Cache each fetched model as new.
            for latestModel in latest {
                try? await insert(model: latestModel)
            }
            return latest as! T
        }
        
    }
    
    /**
     Fetch a collection of data from the Canvas API. Also provides cached version via closure (if any). No filtering.
     - Parameters:
        - request: the desired API query for a **collection** of models.
        - onCacheReceive: a closure for early execution when cached version is received - if any.
     - Returns: An array of models concerning the desired query.
     **/
    func defaultAndFetch<T: Codable & Collection>(
        _ request: CanvasRequest,
        onCacheReceive: ([T.Element]?) -> Void
    ) async throws -> T where T.Element : Cacheable {
        return try await defaultAndFetch<T, String>(request, condition: nil as LookupCondition<T.Element, String>?, onCacheReceive: onCacheReceive)
    }
    
    /**
     Fetch a single instance of data from the Canvas API. Also provides cached version via closure (if any). No filtering.
     - Parameters:
        - request: the desired API query for a **single** model.
        - onCacheReceive: a closure for early execution when cached version is received - if any.
     - Returns: An array of size 1, containing the model concerning the request.
     **/
    func defaultAndFetchSingle<T: Cacheable>(
        _ request: CanvasRequest,
        onCacheReceive: ([T]?) -> Void
    ) async throws -> [T] {
        // To check if query is for single model (not a collection)
        guard !request.yieldsCollection, let uniqueId = request.id else {
            preconditionFailure("Attempted to fetch a single model for request with yieldsCollection: \(request.yieldsCollection), uniqueId: \(request.id ?? "nil"). Expected (false, non-nil value).")
        }
         
        return try await defaultAndFetch<[T], String>(
            request,
            condition: LookupCondition.equals(keypath: \.id, value: uniqueId) as LookupCondition<T, String>?,
            onCacheReceive: onCacheReceive
        )
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
    
    func insert(model: Any) async throws {
        // if data itself is cacheable -> save, if data is an array of cacheables -> save each individually
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
    case failedToDecode(msg: String), fetchFailed(msg: String), invalidURL(msg: String), failedToEncode
}
