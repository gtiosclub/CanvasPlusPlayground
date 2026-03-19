//
//  SpotlightManager.swift
//  CanvasPlusPlayground
//
//  Created by Carson McNeill on 3/9/26.
//

import CoreSpotlight
import Combine

class SpotlightManager {
    static let shared = SpotlightManager()
    
    private var currentSearchQuery: CSSearchQuery?
    
    func indexItem(_ items: [any SpotlightSearchable]) {
        let searchableItems = items.map { item in
            CSSearchableItem(
                uniqueIdentifier: item.spotlightIdentifier,
                domainIdentifier: item.spotlightDomain,
                attributeSet: item.spotlightAttributeSet
            )
        }
        
        CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
            if let error = error {
                print("Error indexing items: \(error.localizedDescription)")
            }
        }
    }
    
    func search(query: String) -> AnyPublisher<[CSSearchableItem], Never> {
        let subject = PassthroughSubject<[CSSearchableItem], Never>()
        
        currentSearchQuery?.cancel()
        
        // Simple query string: titles and descriptions containing the query.
        // The "c" after the string literal makes it case-insensitive.
        let queryString = "title == \"*\(query)*\"c || contentDescription == \"*\(query)*\"c"
        let queryContext = CSSearchQueryContext()
        
        queryContext.fetchAttributes = ["title", "contentDescription", "itemIdentifier"]
        
        let searchQuery = CSSearchQuery(queryString: queryString, queryContext: queryContext)

        
        var results: [CSSearchableItem] = []
        
        searchQuery.foundItemsHandler = { items in
            results.append(contentsOf: items)
        }
        
        searchQuery.completionHandler = { error in
            if let error = error {
                print("Search error: \(error.localizedDescription)")
            }
            subject.send(results)
            subject.send(completion: .finished)
        }
        
        currentSearchQuery = searchQuery
        searchQuery.start()
        
        return subject.eraseToAnyPublisher()
    }
}
