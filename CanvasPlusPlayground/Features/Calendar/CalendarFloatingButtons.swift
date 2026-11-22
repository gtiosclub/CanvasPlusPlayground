//
//  CalendarFloatingButtons.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 11/22/26.
//

import SwiftUI

struct CalendarFloatingButtons: View {
    let addAction: () -> Void
    let assistantAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Button("Add Item", systemImage: "plus", action: addAction)
            Button("Ask AI", systemImage: "sparkles", action: assistantAction)
        }
        .labelStyle(.iconOnly)
        .font(.title2)
        .bold()
        .buttonStyle(FloatingCircleButtonStyle())
        .padding(24)
    }
}

private struct FloatingCircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .frame(width: 60, height: 60)
            .background(.ultraThinMaterial, in: .circle)
            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.snappy, value: configuration.isPressed)
    }
}
