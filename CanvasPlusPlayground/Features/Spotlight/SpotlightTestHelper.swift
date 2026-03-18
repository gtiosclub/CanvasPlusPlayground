//
//  SpotlightTestHelper.swift
//  CanvasPlusPlayground
//
//  Created by Carson McNeill on 3/9/26.
//

import Foundation
import CoreSpotlight

struct MockSpotlightItem: SpotlightSearchable {
    let id: String
    let title: String
    var subtitle: String
    let description: String
    
    var spotlightIdentifier: String { "mock_\(id)" }
    var spotlightDomain: String { "com.canvas.test" }
    
    var spotlightAttributeSet: CSSearchableItemAttributeSet {
        let set = CSSearchableItemAttributeSet(contentType: .item)
        set.title = title
        set.contentDescription = description
        return set
    }
}

extension MockSpotlightItem {
    static let sample = MockSpotlightItem(
        id: "123", 
        title: "Test Spotlight Entry",
        subtitle: "Welcome to the great world of spotlight",
        description: "If you see this, Carson is experiencing bugs!"
    )
}
