//
//  APIRequest+Storage.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/21/24.
//

import Foundation
import SwiftData

extension CacheableAPIRequest {
    fileprivate var loadDescriptor: FetchDescriptor<PersistedModel> {
        // Join custom predicate with id-filtering predicate

        var cacheDescriptor = FetchDescriptor<PersistedModel>()

        let customPred = self.customPredicate
        let idPred = self.idPredicate
        cacheDescriptor.predicate = #Predicate {
            customPred.evaluate($0) && idPred.evaluate($0)
        }
        return cacheDescriptor
    }

    /// Only loads from storage, doesn't make a network call
    @MainActor
    func load(from repository: CanvasRepository, loadingMethod: LoadingMethod<Self>) async throws -> [PersistedModel]? {
        var descriptor = loadDescriptor

        if case let .page(order) = loadingMethod {
            descriptor.fetchOffset = self.perPage * (order - 1)
            descriptor.fetchLimit = self.perPage
            descriptor.sortBy = [SortDescriptor(\.id)] // default sort required for pagination
        }

        // Get cached data for this type then filter to only get models related to `request`
        let cached: [PersistedModel]? = try repository.get(descriptor: descriptor)

        return cached
    }

    /// Number of occurences of models related to request
    @MainActor
    func loadCount(from repository: CanvasRepository) async throws -> Int {
        return try repository.count(descriptor: loadDescriptor)
    }
}
