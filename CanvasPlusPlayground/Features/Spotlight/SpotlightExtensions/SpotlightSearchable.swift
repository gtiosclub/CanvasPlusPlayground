//
//  SpotlightSearchable.swift
//  CanvasPlusPlayground
//
//  Created by Carson McNeill on 3/9/26.
//

import CoreSpotlight
import UniformTypeIdentifiers // TODO: Check if this is the correct import

protocol SpotlightSearchable: Identifiable {
    var id: String { get }
    var title: String { get }
    var subtitle: String { get }
    
    var spotlightIdentifier: String { get }
    var spotlightDomain: String { get }
    var spotlightAttributeSet: CSSearchableItemAttributeSet { get }
}
