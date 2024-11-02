//
//  CanvasService.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/14/24.
//

import Foundation

struct CanvasService {
    static let shared = CanvasService()
    
    private let repository = CanvasRepository()
    
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
    
    func defaultAndFetch<T: Cacheable>(_ request: CanvasRequest, onCacheReceive: (T) -> Void) async throws -> T {
        // Cache fetch
        
        // If subject itself is cached
        if let id = request.id,
            let cached: T = try await repository.get(id: id as! T.ID) {
            onCacheReceive(cached)
        }
        
        return try await fetch(request)
    }
    
    /// To fetch a collection of data from the Canvas API, only!
    func defaultAndFetch<T: Codable>(_ request: CanvasRequest, onCacheReceive: ([T.Element]) -> Void) async throws -> T where T : Collection, T.Element : Cacheable {
        // Cache fetch
        
        // If contents of subject are cached
        if let cached: [T.Element] = try await repository.get<T.Element>() {
            onCacheReceive(cached)
        }
        
        return try await fetch(request)
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
            
            // if data itself is cacheable -> save, if data is an array of cacheables -> wrap-around
            if let toCache = decoded as? (any Cacheable) {
                try await repository.save(toCache)
            } else if let arrayOfCacheables = decoded as? [any Cacheable] {
                for cacheable in arrayOfCacheables {
                    try await repository.save(cacheable)
                }
            }
            
            return decoded
        } catch {
            throw NetworkError.failedToDecode(msg: error.localizedDescription)
        }
    }
    
    // TODO: new method + dispatch queue for multiple concurrent requests - Aziz
}

enum NetworkError: Error {
    case failedToDecode(msg: String), fetchFailed(msg: String), invalidURL(msg: String)
}
