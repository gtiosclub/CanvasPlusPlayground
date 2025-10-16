//
//  CompatibleGlassEffectViewModifier.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/11/25.
//

import SwiftUI

enum CompatibleGlassEffect {
    case clear
    case regular
    case identity

    @available(macOS 26.0, iOS 26.0, *)
    var glassEffect: Glass {
        switch self {
        case .clear: .clear
        case .regular: .regular
        case .identity: .identity
        }
    }
}

private struct CompatibleGlassEffectViewModifier<S: Shape>: ViewModifier {
    let glass: CompatibleGlassEffect
    let isInteractive: Bool
    let shape: S

    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            content
                .glassEffect(
                    glass.glassEffect.interactive(isInteractive),
                    in: shape
                )
        } else {
            content.background(.thinMaterial, in: shape)
        }
    }
}

extension View {
    func compatibleGlassEffect<S: Shape>(
        _ glass: CompatibleGlassEffect = .regular,
        isInteractive: Bool = false,
        in shape: S
    ) -> some View {
        modifier(
            CompatibleGlassEffectViewModifier(
                glass: glass,
                isInteractive: isInteractive,
                shape: shape
            )
        )
    }
    
    func compatibleGlassEffect(
        _ glass: CompatibleGlassEffect = .regular
    ) -> some View {
        compatibleGlassEffect(glass, in: RoundedRectangle(cornerRadius: 12))
    }
}
