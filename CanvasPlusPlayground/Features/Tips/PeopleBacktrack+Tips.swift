//
//  PeopleBacktrack+Tips.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/18/25.
//

import Foundation
import TipKit

struct PeopleBacktrackTip: Tip {
    var title: Text {
        Text("People Backtrack")
    }

    var message: Text? {
        Text("See what common courses you share with other students.")
    }

    var options: [TipOption] {
        MaxDisplayCount(1)
    }
}
