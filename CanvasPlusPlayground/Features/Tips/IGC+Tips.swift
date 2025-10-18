//
//  IGC+Tips.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/18/25.
//

import Foundation
import TipKit

struct IGCTip: Tip {
    var title: Text {
        Text("Calculate grade with Intelligent Grade Calculator")
    }

    var message: Text? {
        Text("Extract weights from canvas syllabus and modify grades to calculate your final grade.")
    }

    var options: [TipOption] {
        MaxDisplayCount(1)
    }
}
