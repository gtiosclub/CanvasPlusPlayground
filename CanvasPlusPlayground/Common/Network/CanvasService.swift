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
    
    var completedRequests: Set<CanvasRequest> = []
    let completedRequestsQueue = DispatchQueue(label: "com.example.completedRequestsQueue")
    
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
    func load<T: Cacheable>(_ request: CanvasRequest, descriptor: FetchDescriptor<T> = .init()) async throws -> [T]? {
        if !(request.associatedModel == T.self || request.associatedModel == [T].self){
            preconditionFailure("Provided generic type T = \(T.self) does not match the expected `associatedModel` type \(request.associatedModel) in request.")
        }
        
        // Join custom predicate with id-filtering predicate
        var cacheDescriptor = descriptor
        let customPred = cacheDescriptor.predicate ?? .isAlwaysTrue()
        let idPred = request.cacheFilter() as Predicate<T>
        cacheDescriptor.predicate = #Predicate {
            customPred.evaluate($0) && idPred.evaluate($0)
        }
                
        // Get cached data for this type then filter to only get models related to `request`
        let cached: [T]? = try await repository.get(descriptor: cacheDescriptor)
        
        return cached
    }
    
    func loadCount<T: Cacheable>(_ request: CanvasRequest, descriptor: FetchDescriptor<T>) async throws -> Int {
        if !(request.associatedModel == T.self || request.associatedModel == [T].self){
            preconditionFailure("Provided generic type T = \(T.self) does not match the expected `associatedModel` type \(request.associatedModel) in request.")
        }
        
        // Join custom predicate with id-filtering predicate
        var cacheDescriptor = descriptor
        let customPred = cacheDescriptor.predicate ?? .isAlwaysTrue()
        let idPred = request.cacheFilter() as Predicate<T>
        cacheDescriptor.predicate = #Predicate {
            customPred.evaluate($0) && idPred.evaluate($0)
        }
                
        return try await repository.count(descriptor: cacheDescriptor)
    }
    
    func syncWithAPI<T: Cacheable>(
        _ request: CanvasRequest,
        descriptor: FetchDescriptor<T> = FetchDescriptor<T>(),
        onNewBatch: ([T]) -> Void = { _ in }
    ) async throws -> [T] {
        let cached = try await load(request, descriptor: descriptor) ?? []
        
        return try await syncWithAPI(
            request,
            descriptor: descriptor,
            using: cached,
            onNewBatch: onNewBatch
        )
    }
    
    
    private func syncWithAPI<T: Cacheable>(
        _ request: CanvasRequest,
        descriptor: FetchDescriptor<T> = FetchDescriptor<T>(),
        using cache: [T],
        onNewBatch: ([T]) -> Void
    ) async throws -> [T] {
        if !(request.associatedModel == T.self || request.associatedModel == [T].self){
            preconditionFailure("Provided generic type T = \(T.self) does not match the expected `associatedModel` type \(request.associatedModel) in request.")
        }
        
        let cacheLookup = Dictionary(uniqueKeysWithValues: cache.map { ($0.id, $0) } )
        
        let updateStorage: ([T]) async -> [T] = { newModels in
            // New batch received
            
            // Filter as desired by caller
            let newModelsFilteredAccordingToDescriptor = (try? filterByDescriptor(descriptor, models: newModels)) ?? newModels
            
            var latest = newModelsFilteredAccordingToDescriptor
            // Replace merge fetched model into cached model OR cache fetched model as new.
            for (i, latestModel) in latest.enumerated() {
                if let matchedCached = cacheLookup[latestModel.id] {
                    await repository.merge(other: latestModel, into: matchedCached)
                    latest[i] = matchedCached
                } else {
                    await repository.insert(latestModel)
                }
            }
            
            
            let writeKeyPath = request.writableIdKeypath() as ReferenceWritableKeyPath<T, String>?
            if let writeKeyPath {
                // Store the request / parent id in each model so that we can recall all models when repeating a request
                for model in latest {
                    await model.update(keypath: writeKeyPath, value: request.id)
                }
            }
            
            
            
            return latest
        }
        
        // Fetch newest version from API, then filter as desired by caller.
        var latest: [T] = try await {
            
            // Adjust `fetch` generic parameter based on whether request is for a collection.
            let fetched: [T]
            if request.associatedModel is any Collection.Type {
                fetched = try await fetch(request, onNewPage: { batch in
                    let transformed = await updateStorage(batch)
                    
                    onNewBatch(transformed)
                })
            } else {
                fetched = await updateStorage( [try await fetch(request)] )
            }
            
            let filtered = (try? filterByDescriptor(descriptor, models: fetched)) ?? fetched
            return filtered
        }()
        
        // User storage version of model
        for (i, latestModel) in latest.enumerated() {
            if let matchedCached = cacheLookup[latestModel.id] {
                latest[i] = matchedCached
            }
        }
        
        await repository.flush()
        
        return latest
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
    func loadAndSync<T: Cacheable>(
        _ request: CanvasRequest,
        descriptor: FetchDescriptor<T> = FetchDescriptor<T>(),
        onCacheReceive: ([T]?) -> Void = { _ in },
        onNewBatch: ([T]) -> Void = { _ in }
    ) async throws -> [T] {
        if !(request.associatedModel == T.self || request.associatedModel == [T].self){
            preconditionFailure("Provided generic type T = \(T.self) does not match the expected `associatedModel` type \(request.associatedModel) in request.")
        }
        
        let cached: [T]? = try await load(request, descriptor: descriptor)
        onCacheReceive(cached) // Share cached version with caller.
            
        let latest = try await syncWithAPI(request, descriptor: descriptor, using: cached ?? [], onNewBatch: onNewBatch)
        
        return latest
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
    
    func clearStorage() {
        repository.modelContainer.deleteAllData()
    }
    
    // MARK: Helpers
    
    private func decodeData<T: Codable>(arg: (Data, URLResponse)) throws -> T {
        let (data, _) = arg
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(T.self, from: data)
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
    
    mutating func markRequestAsCompleted(_ request: CanvasRequest) {
        completedRequestsQueue.sync {
            let _ = self.completedRequests.insert(request)
        }
    }
    
    func isRequestCompleted(_ request: CanvasRequest) -> Bool {
        completedRequests.contains(request)
    }
}
