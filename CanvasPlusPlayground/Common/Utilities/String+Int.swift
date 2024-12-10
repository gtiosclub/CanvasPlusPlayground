//
//  String+Int.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 11/8/24.
//

import Foundation

extension String {
    var asInt: Int? {
        Int(self)
    }
}

extension Int {
    var asString: String {
        "\(self)"
    }
}
