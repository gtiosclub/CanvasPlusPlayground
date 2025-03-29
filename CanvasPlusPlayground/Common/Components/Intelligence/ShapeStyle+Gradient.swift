//
//  ShapeStyle+Gradient.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/23/25.
//

import SwiftUI

extension ShapeStyle where Self == AnyShapeStyle {
    static func animatedGradient(time: TimeInterval, gridSize: Int = 3, colors: [Color]) -> Self {
        AnyShapeStyle(ShaderLibrary.default.grainGradient(
            .boundingRect,
            .float(3),
            .float(time),
            .colorArray(colors)
        ))
    }

    static func intelligenceGradient() -> Self {
        AnyShapeStyle(
            LinearGradient(
                colors: IntelligenceManager.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
