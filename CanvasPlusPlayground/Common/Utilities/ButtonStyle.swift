//
//  ButtonStyle.swift
//  CanvasPlusPlayground
//
//  Created by João Pozzobon on 3/3/25.
//

import SwiftUI

struct ElasticButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .elastic(active: configuration.isPressed)
    }
}

struct ElasticModifier: ViewModifier {
    var active: Bool
    @State var hovering = false
    @Environment(\.isEnabled) var isEnabled

    func body(content: Content) -> some View {
        content
            .scaleEffect(active ? 0.95 : (hovering && isEnabled ? 1.025 : 1.0))
            .animation(.elastic, value: active)
            .animation(.elastic, value: hovering)
            .onHover {
                hovering = $0
            }
            .onChange(of: active) { _, value in
                if value {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
            .opacity(isEnabled ? 1.0 : 0.5)
    }
}

extension View {
    func elastic(active: Bool) -> some View {
        self.modifier(ElasticModifier(active: active))
    }
}

extension Animation {
    static var elastic: Self {
        .spring(response: 0.15, dampingFraction: 0.85)
    }
}
