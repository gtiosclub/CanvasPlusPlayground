//
//  CustomizeCourseView+Tips.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/18/25.
//

import Foundation
import TipKit

struct CustomizeCourseTip: Tip {
    var title: Text {
        Text("Customize Course")
    }

    var message: Text? {
        Text("Tap \(Image(systemName: "ellipsis")) to customize course with custom name, color, and symbol.")
    }

    var options: [TipOption] {
        MaxDisplayCount(1)
    }
}
