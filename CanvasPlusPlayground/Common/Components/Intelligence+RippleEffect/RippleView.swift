//
//  IntelligenceContentView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/23/25.
//

import SwiftUI

struct RippleView<V: View>: View {
    let condition: Bool
    let content: V

    @State private var center: CGPoint = .zero

    init(condition: Bool, @ViewBuilder content: @escaping () -> V) {
        self.condition = condition
        self.content = content()
    }

    var body: some View {
        content
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
}
