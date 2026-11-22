//
//  ScaledFont.swift
//  CanvasPlusPlayground
//
//  Created by Kareem on 10/24/26.
//

import SwiftUI

private struct ScaledFont: ViewModifier {
    @ScaledMetric private var size: CGFloat

    let weight: Font.Weight
    let design: Font.Design

    init(size: CGFloat, relativeTo textStyle: Font.TextStyle, weight: Font.Weight, design: Font.Design) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }
}

extension View {
    /// Sets a system font that keeps its size at the default text size and grows with Dynamic Type like a text style.
    /// - Parameters:
    ///   - size: The point size at the default text size.
    ///   - textStyle: The text style whose Dynamic Type scaling the size follows.
    ///   - weight: The font weight.
    ///   - design: The font design.
    func scaledFont(
        size: CGFloat,
        relativeTo textStyle: Font.TextStyle,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> some View {
        modifier(ScaledFont(size: size, relativeTo: textStyle, weight: weight, design: design))
    }
}
