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
        
        results = database.filter { item in
            (item.spotlightAttributeSet.title ?? "").localizedCaseInsensitiveContains(query) ||
            (item.spotlightAttributeSet.contentDescription ?? "").localizedCaseInsensitiveContains(query)
        }
    }
}
