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

    /**
     Fetch a collection of data from the Canvas API. Also provides cached version via closure (if any). Allows filtering.
     - Parameters:
        - request: the desired API query for a **collection** of models.
        - condition: an optimized filter to be performed in the query.
        - onCacheReceive: a closure for early execution when cached version is received - if any.
        - onNewBatch: if the request involves pagination, this closure will be executed upon arrival of each batch
     - Returns: An array of models concerning the desired query.
     **/
    func defaultAndFetch<T: Codable & Collection, V: Equatable>(
        _ request: CanvasRequest,
        condition: LookupCondition<T.Element, V>?,
        onCacheReceive: ([T.Element]?) -> Void = { _ in },
        onNewBatch: ([T.Element]) -> Void = { _ in }
    ) async throws -> T where T.Element : Cacheable {
        if !(request.associatedModel == T.self || request.associatedModel == T.Element.self){
            preconditionFailure("Provided generic type T = \(T.self) does not match the expected `associatedModel` type \(request.associatedModel) in request.")
        }
                
        // Get cached data for this type then filter to only get models related to `request`
        let cached: [T.Element]? = try await repository.get(condition: condition)?.filter(request.cacheFilter)
        onCacheReceive(cached) // Share cached version with caller.
            
        // Search cache by id
        let cacheLookup = Dictionary(uniqueKeysWithValues: (cached ?? []).map { ($0.id, $0) })
        
        let cachedBatch: (T) async -> [T.Element] = { page in
            // New batch received
            
            // Filter as desired by caller
            var latest = page.filter { ((try? condition?.expression().evaluate($0)) ?? true) }
            
            // Replace merge fetched model into cached model OR cache fetched model as new.
            for (i, latestModel) in latest.enumerated() {
                if let matchedCached = cacheLookup[latestModel.id] {
                    await matchedCached.merge(with: latestModel)
                    latest[i] = matchedCached
                } else {
                    try? await repository.insert(latestModel)
                }
            }
            
            // Store the request / parent id in each model so that we can recall all models for that parent
            if let id = request.id {
                latest.forEach { $0.parentId = id }
            }
            
            return latest
        }
        
        // Fetch newest version from API, then filter as desired by caller.
        var latest: [T.Element] = try await {
            
            // Adjust `fetch` generic parameter based on whether request is for a collection.
            let fetched: [T.Element]
            if request.associatedModel is any Collection.Type {
                fetched = try await fetch(request, onNewPage: {
                    guard let batch = $0 as? T else {
                        print("Couldn't unwrap batch to T from [T.Element].")
                        return
                    }
                    let transformed = await cachedBatch(batch)
                    
                    onNewBatch(transformed)
                })
            } else {
                let fetchedItem: T.Element = try await fetch(request, onNewPage: {
                    guard let batch = [$0] as? T else {
                        print("Couldn't unwrap batch to T from [T.Element].")
                        return
                    }
                    let model = await cachedBatch(batch) // $0 is T.Element but should be T
                    onNewBatch(model)
                })
                fetched = [fetchedItem]
            }
            
            return fetched.filter { ((try? condition?.expression().evaluate($0)) ?? true) }
        }()
        
        for (i, latestModel) in latest.enumerated() {
            if let matchedCached = cacheLookup[latestModel.id] {
                latest[i] = matchedCached
            }
        }
        
        repository.flush()
        
        return latest as! T
    }
    
    /**
     Fetch a collection of data from the Canvas API. Also provides cached version via closure (if any). No filtering.
     - Parameters:
        - request: the desired API query for a **collection** of models.
        - onCacheReceive: a closure for early execution when cached version is received - if any.
        - onNewBatch: if the request involves pagination, this closure will be executed upon arrival of each batch
     - Returns: An array of models concerning the desired query.
     **/
    func defaultAndFetch<T: Codable & Collection>(
        _ request: CanvasRequest,
        onCacheReceive: ([T.Element]?) -> Void,
        onNewBatch: ([T.Element]) -> Void = { _ in}
    ) async throws -> T where T.Element : Cacheable {
        return try await defaultAndFetch<T, String>(
            request,
            condition: nil as LookupCondition<T.Element, String>?,
            onCacheReceive: onCacheReceive,
            onNewBatch: onNewBatch
        )
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
            onCacheReceive: onCacheReceive,
            onNewBatch: { _ in}
        )
    }
    
    // MARK: Network Requests
    
    /// To fetch data from the Canvas API in batches!
    func fetch<T>(
        _ request: CanvasRequest,
        onNewPage: (T) async -> Void = { _ in}
    ) async throws -> T where T : Collection, T : Codable, T.Element : Codable {
        
        // If the request is to be paginated and fetched type T is a collection -> fetch batch by batch
        let fetched = try await fetchBatch(request, oneNewBatch: { batch in
            try await onNewPage(decodeData(arg: batch))
        }).map { try decodeData(arg: $0) as T }
                
        guard let result = fetched.reduce([], +) as? T else {
            throw NetworkError.failedToDecode(msg: "Result could not be cast to T.")
        }
        return result
       
    }
    
    /// To fetch data from the Canvas API, only!
    func fetch<T>(
        _ request: CanvasRequest,
        onNewPage: (T) async -> Void = { _ in}
    ) async throws -> T where T : Codable {
        
        // API fetch
        let result = try await CanvasService.shared.fetchResponse(request)
        
        let decoded = try decodeData(arg: result) as T
        
        await onNewPage(decoded)
        return decoded
        
    }
    
    func fetchResponse(_ request: CanvasRequest) async throws -> (data: Data, response: URLResponse) {
        guard let url = request.url else { throw NetworkError.invalidURL(msg: request.path) }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NetworkError.fetchFailed(msg: response.description)
            }
            
            return (data, response)
        } catch {
            throw NetworkError.fetchFailed(msg: error.localizedDescription)
        }
    }

    func fetchBatch(
        _ request: CanvasRequest,
        oneNewBatch: (((data: Data, url: URLResponse)) async throws -> ())
    ) async throws -> [(data: Data, url: URLResponse)] {
        /*
         var currUrl =
         1) while loop
            a) people, newUrl = fetch(currUrl)
            b) onNewBatch(people)
            c) currUrl = newUrl
            d) if (newUrl = nil) break
         */

        var returnData: [(data: Data, url: URLResponse)] = []
        var currURL = request.url;
        var count = 1
        while let url = currURL {
            var request = URLRequest(url: url)

            request.httpMethod = "GET"

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("HTTP error: $\(response)$")
                throw NetworkError.fetchFailed(msg: response.description)
            }
            returnData.append((data, response))
            
            try await oneNewBatch((data, response))

            guard let linkValue = httpResponse.allHeaderFields["Link"] as? String else {
                print("No link field data")
                break
            }

            let r = /<([^>]+)>; rel="next"/

            guard let match = try r.firstMatch(in: linkValue) else {
                print("No matching regex")
                break
            }

            let urlString = String(match.output.1).trimmingCharacters(in: .whitespacesAndNewlines)

            currURL = URL(string: urlString)
            currURL = currURL?.appending(queryItems: [
                URLQueryItem(name: "access_token", value: StorageKeys.accessTokenValue)
            ])

            count += 1
        }
        
        return returnData
    }
    
    // MARK: Repository actions
    
    @MainActor
    func setupRepository() async {
        repository.modelContainer.mainContext.autosaveEnabled = true
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
    
    // MARK: Helpers
    
    func decodeData<T: Codable>(arg: (Data, URLResponse)) throws -> T {
        let (data, _) = arg
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(T.self, from: data)
    }
}

private extension CanvasRequest {
    /// If the request is for a single model, it returns a filter that checks for the model's id. If the request is for multiple models, it filters based on the model's parent ids.
    func cacheFilter<M: Cacheable>(_ model: M) -> Bool {
        let expectedM = self.associatedModel
        
        if (expectedM is any Cacheable.Type) {
            return model.id == self.id
        } else if let _ = expectedM as? any Collection<M>.Type {
            return model.parentId == self.id
        }
        
        return false
    }
}

