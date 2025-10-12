//
//  ShimmerEffect.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/11/25.
//

import SwiftUI

private struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    var duration: Double = 2.0
    var bounce: Bool = false

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .white.opacity(0.6), location: 0.45),
                                    .init(color: .white.opacity(0.8), location: 0.5),
                                    .init(color: .white.opacity(0.6), location: 0.55),
                                    .init(color: .clear, location: 1)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: phase * geometry.size.width - geometry.size.width)
                        .blendMode(.plusLighter)
                }
            }
            .mask {
                content
            }
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: bounce)
                ) {
                    phase = 2
                }
            }
    }
}

extension View {
    func shimmer(duration: Double = 2.0, bounce: Bool = false) -> some View {
        modifier(ShimmerEffect(duration: duration, bounce: bounce))
    }
}
