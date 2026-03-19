//
//  CourseSpotlight.swift
//  CanvasPlusPlayground
//
//  Created by Carson McNeill on 3/9/26.
//

import CoreSpotlight
import Foundation

extension Course: SpotlightSearchable {
    var title: String {
        displayName
    }
    
    var subtitle: String {
        "Course Code: \(courseCode ?? "N/A")"
    }
    
    var spotlightIdentifier: String { "course_\(id)" }
    var spotlightDomain: String { "com.canvas.course" }
    
    var spotlightAttributeSet: CSSearchableItemAttributeSet {
        let set = CSSearchableItemAttributeSet(contentType: .item)
        set.title = title
        set.contentDescription = subtitle
        
        // TODO: Add course icons
        
        return set
    }
}
