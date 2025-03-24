//
//  IntelligenceContentView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/23/25.
//

import SwiftUI

struct IntelligenceContentView<V: View>: View {
    @Namespace private var namespace

    /// This view ripples upon change of this condition
    let condition: Bool
    /// This boolean determines whether the background of the view is an outline stroke or is filled.
    let isOutline: Bool
    /// The view's contents
    let content: V

    @State private var center: CGPoint = .zero
    @State private var startTime = Date.now

    /// A view designated for promoting intelligence features within the app.
    /// - Parameters:
    ///   - condition: This view ripples upon change of this condition.
    ///   - isOutline: This boolean determines whether the background of the view is an outline stroke or is filled.
    ///   If `nil` is passed in, `condition` is used instead.
    ///   - content: The view's contents
    init(condition: Bool, isOutline: Bool? = nil, @ViewBuilder content: @escaping () -> V) {
        self.condition = condition
        self.isOutline = isOutline ?? condition
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
            .modifier(
                RippleEffect(
                    at: center,
                    trigger: condition
                )
            )
    }

    private var cardBackground: some View {
        TimelineView(.animation) { _ in
            let elapsedTime = startTime.distance(to: Date.now)

            if !isOutline {
                RoundedRectangle(cornerRadius: 8.0)
                    .fill(
                        .animatedGradient(
                            time: elapsedTime,
                            colors: IntelligenceManager.gradientColors
                        )
                    )
                    .matchedGeometryEffect(id: "background", in: namespace)
            } else {
                RoundedRectangle(cornerRadius: 8.0)
                    .strokeBorder(
                        .animatedGradient(
                            time: elapsedTime,
                            colors: IntelligenceManager.gradientColors
                        ),
                        lineWidth: 2.0
                    )
                    .matchedGeometryEffect(id: "background", in: namespace)
            }
        }
    }
}
