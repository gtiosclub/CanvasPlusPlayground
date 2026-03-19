//
//  SpotlightViewModel.swift
//  CanvasPlusPlayground
//
//  Created by Carson McNeill on 3/18/26.
//

import Foundation
import Combine
import CoreSpotlight

class SpotlightViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var results: [any SpotlightSearchable] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let spotlightManager = SpotlightManager.shared
    
    // MARK: - Debug Local Database
    private let database: [any SpotlightSearchable] = [
        MockSpotlightItem.sample,
    ]
    
    init() {
        setupSearchPipeline()
    }
    
    private func setupSearchPipeline() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            results = []
            return
        }
        
        // 1. First search local/fallback database for quick results
        let localResults = database.filter { item in
            item.title.localizedCaseInsensitiveContains(query) ||
            item.subtitle.localizedCaseInsensitiveContains(query)
        }
        
        // 2. Then trigger Core Spotlight search for indexed items
        spotlightManager.search(query: query)
            .receive(on: RunLoop.main)
            .sink { [weak self] spotlightItems in
                guard let self = self else { return }
                
                let mappedSpotlightResults = spotlightItems.map { SpotlightSearchResult(item: $0) }
                
                var combinedResults = localResults
                for result in mappedSpotlightResults {
                    if !combinedResults.contains(where: { $0.spotlightIdentifier == result.spotlightIdentifier }) {
                        combinedResults.append(result)
                    }
                }
                
                self.results = combinedResults
            }
            .store(in: &cancellables)
    }
}
