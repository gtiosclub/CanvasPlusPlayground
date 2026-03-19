//
//  SpotlightSearchable.swift
//  CanvasPlusPlayground
//
//  Created by Carson McNeill on 3/9/26.
//

import CoreSpotlight
import UniformTypeIdentifiers

protocol SpotlightSearchable: Identifiable {
    var id: String { get }
    var title: String { get }
    var subtitle: String { get }
    
    var spotlightIdentifier: String { get }
    var spotlightDomain: String { get }
    var spotlightAttributeSet: CSSearchableItemAttributeSet { get }
}


struct SpotlightSearchResult: SpotlightSearchable {
    let id: String
    let title: String
    let subtitle: String
    let spotlightIdentifier: String
    let spotlightDomain: String
    
    var spotlightAttributeSet: CSSearchableItemAttributeSet {
        let set = CSSearchableItemAttributeSet(contentType: .item)
        set.title = title
        set.contentDescription = subtitle
        return set
    }
    
    init(item: CSSearchableItem) {
        self.id = item.uniqueIdentifier
        self.title = item.attributeSet.title ?? ""
        self.subtitle = item.attributeSet.contentDescription ?? ""
        self.spotlightIdentifier = item.uniqueIdentifier
        self.spotlightDomain = item.domainIdentifier ?? ""
    }
}
