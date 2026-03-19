//
//  AssignmentSpotlight.swift
//  CanvasPlusPlayground
//
//  Created by Carson McNeill on 3/9/26.
//

import CoreSpotlight
import Foundation

extension Assignment: SpotlightSearchable {
    var title: String {
        name
    }
    
    var subtitle: String {
        "Due: \(dueAt ?? "No due date")"
    }
    
    var spotlightIdentifier: String { "assignment_\(id)" }
    var spotlightDomain: String { "com.canvas.assignment" }
    
    var spotlightAttributeSet: CSSearchableItemAttributeSet {
        let set = CSSearchableItemAttributeSet(contentType: .item)
        set.title = title
        set.contentDescription = subtitle
        return set
    }
}
