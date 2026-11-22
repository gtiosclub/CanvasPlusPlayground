//
//  CalendarFloatingButtons.swift
//  CanvasPlusPlayground
//
//  Created by Kareem Alaiwat on 11/22/26.
//

import SwiftUI

struct CalendarFloatingButtons: View {
    let addAction: () -> Void

    var body: some View {
        Button("Add Item", systemImage: "plus", action: addAction)
            .labelStyle(.iconOnly)
            .font(.system(size: 20, weight: .semibold))
            .buttonStyle(FloatingButtonStyle())
            .padding(24)
    }
}

// Matches the + button in CourseOverviewView: 52pt rounded square on material.
private struct FloatingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .frame(width: 52, height: 52)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.snappy, value: configuration.isPressed)
    }
}
