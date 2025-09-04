//
//  IntelligenceContentView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/23/25.
//

import SwiftUI

/// A view designated for promoting intelligence features within the app.
@available(macOS 26.0, iOS 26.0, *)
struct IntelligenceContentView<V: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Namespace private var namespace

    /// This view ripples upon change of this condition
    let condition: Bool
    /// If this boolean is `true`, the background of the view appears more faded, allowing the
    /// content to appear more prominent.
    let isContentProminent: Bool
    /// The view's contents
    let content: V

    @State private var center: CGPoint = .zero
    @State private var startTime = Date.now

    /// A view designated for promoting intelligence features within the app.
    /// - Parameters:
    ///   - condition: This view ripples upon change of this condition.
    ///   - isOutline: If this boolean is `true`, the background of the view appears more faded, allowing the content to appear more prominent
    ///   If `nil` is passed in, `condition` is used instead.
    ///   - content: The view's contents
    init(condition: Bool, isContentProminent: Bool? = nil, @ViewBuilder content: @escaping () -> V) {
        self.condition = condition
        self.isContentProminent = isContentProminent ?? condition
        self.content = content()
    }

    var body: some View {
        content
            .background {
                cardBackground
            }
            .background {
                Color.clear
                    .onGeometryChange(for: CGSize.self) { proxy in
                        proxy.size
                    } action: { newValue in
                        center = newValue.center
                    }
            }
            .rippleEffect(origin: center, condition: condition)
    }

    private var cardBackground: some View {
        TimelineView(.animation) { _ in
            let elapsedTime = startTime.distance(to: Date.now)

            Rectangle()
                .fill(
                    reduceTransparency ? .intelligenceGradient() :
                            .animatedGradient(
                                time: elapsedTime,
                                colors: IntelligenceSupport.gradientColors
                            )
                )
                .matchedGeometryEffect(id: "background", in: namespace)
                .overlay(
                    isContentProminent ? .ultraThickMaterial : .thinMaterial,
                    in: .rect
                )
        }
    }
}
