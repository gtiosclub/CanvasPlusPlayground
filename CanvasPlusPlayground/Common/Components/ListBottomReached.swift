//
//  ListBottomSpinner.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 1/21/25.
//

import SwiftUI

struct ListBottomReached: ViewModifier {
    @Binding var isLoading: Bool
    @Binding var disabled: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    let yOffset = geometry.frame(in: .scrollView).maxY

                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: yOffset)
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { maxYOffset in
                if maxYOffset < 50 && !isLoading {
                    isLoading = true
                    action()
                }
            }
            .coordinateSpace(.scrollView)
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension List {
    ///
    func bottomSpinner(
        isLoading: Binding<Bool>,
        disabled: Binding<Bool> = .constant(false),
        action: @escaping () -> Void
    ) -> some View {
        modifier(
            ListBottomReached(
                isLoading: isLoading,
                disabled: disabled,
                action: action
            )
        )
    }
}
