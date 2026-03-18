//
//  SpotlightManager.swift
//  CanvasPlusPlayground
//
//  Created by Carson McNeill on 3/9/26.
//

import CoreSpotlight

class SpotlightManager {
    static let shared = SpotlightManager()
    
    func indexItem(_ items: [SpotlightSearchable]) {
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
}
