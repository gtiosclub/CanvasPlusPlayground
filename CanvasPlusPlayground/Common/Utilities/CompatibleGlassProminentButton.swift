//
//  CompatibleGlassProminentButton.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/10/25.
//

import SwiftUI

private struct CompatibleGlassProminentButtonViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}

extension View {
    func compatibleGlassProminentButton() -> some View {
        modifier(CompatibleGlassProminentButtonViewModifier())
    }
}
