//
//  CGSize+Center.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/23/25.
//

import Foundation

extension CGSize {
    var center: CGPoint {
        .init(x: width / 2, y: height / 2)
    }
}
