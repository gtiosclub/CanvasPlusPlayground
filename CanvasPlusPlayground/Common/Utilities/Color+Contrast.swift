//
//  Color+Contrast.swift
//  CanvasPlusPlayground
//
//  Created by Kareem on 10/10/26.
//

import SwiftUI

enum WCAGContrast {
    // WCAG 1.4.3 AA for normal-size text
    static let minimumTextRatio = 4.5

    static func relativeLuminance(linearRed: Double, linearGreen: Double, linearBlue: Double) -> Double {
        0.2126 * clamp(linearRed) + 0.7152 * clamp(linearGreen) + 0.0722 * clamp(linearBlue)
    }

    static func contrastRatio(_ first: Double, _ second: Double) -> Double {
        let lighter = max(first, second)
        let darker = min(first, second)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

private struct ReadableCourseTintModifier: ViewModifier {
    @Environment(\.self) private var environment

    let color: Color?
    let cardOpacity: Double?

    func body(content: Content) -> some View {
        content.tint(color?.readable(against: background, in: environment))
    }

    private var background: Color {
        if let cardOpacity {
            .cardSurface(opacity: cardOpacity, in: environment)
        } else {
            .courseContentBackground(for: environment.colorScheme)
        }
    }
}

private struct ReadableForegroundModifier: ViewModifier {
    @Environment(\.self) private var environment

    let background: Color?

    func body(content: Content) -> some View {
        if let background {
            content.foregroundStyle(background.accessibleForeground(in: environment))
        } else {
            content
        }
    }
}

extension Color.Resolved {
    var relativeLuminance: Double {
        WCAGContrast.relativeLuminance(
            linearRed: Double(linearRed),
            linearGreen: Double(linearGreen),
            linearBlue: Double(linearBlue)
        )
    }

    func contrastRatio(with other: Color.Resolved) -> Double {
        WCAGContrast.contrastRatio(relativeLuminance, other.relativeLuminance)
    }
}

extension Color {
    private static let readableMixSteps = 20

    func accessibleForeground(in environment: EnvironmentValues) -> Color {
        let luminance = resolve(in: environment).relativeLuminance
        let whiteRatio = WCAGContrast.contrastRatio(1, luminance)
        let blackRatio = WCAGContrast.contrastRatio(0, luminance)
        return whiteRatio >= blackRatio ? .white : .black
    }

    func readable(
        against background: Color,
        in environment: EnvironmentValues,
        minimumRatio: Double = WCAGContrast.minimumTextRatio
    ) -> Color {
        let backgroundLuminance = background.resolve(in: environment).relativeLuminance

        func passes(_ color: Color) -> Bool {
            let luminance = color.resolve(in: environment).relativeLuminance
            return WCAGContrast.contrastRatio(luminance, backgroundLuminance) >= minimumRatio
        }

        guard !passes(self) else { return self }

        let reachableTargets = [Color.black, .white].filter(passes)
        for step in 1...Self.readableMixSteps {
            let fraction = Double(step) / Double(Self.readableMixSteps)
            for target in reachableTargets {
                let mixed = mix(with: target, by: fraction)
                if passes(mixed) {
                    return mixed
                }
            }
        }

        let whiteRatio = WCAGContrast.contrastRatio(1, backgroundLuminance)
        let blackRatio = WCAGContrast.contrastRatio(0, backgroundLuminance)
        return whiteRatio >= blackRatio ? .white : .black
    }

    static func courseContentBackground(for colorScheme: ColorScheme) -> Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        if colorScheme == .dark {
            Color(uiColor: .secondarySystemGroupedBackground)
        } else {
            Color(uiColor: .systemGroupedBackground)
        }
        #endif
    }

    static func cardSurface(opacity: Double, in environment: EnvironmentValues) -> Color {
        var secondary = Color.secondary.resolve(in: environment)
        let fraction = opacity * Double(secondary.opacity)
        secondary.opacity = 1
        return courseContentBackground(for: environment.colorScheme)
            .mix(with: Color(secondary), by: fraction, in: .device)
    }
}

extension View {
    /// Tints this view with a course color, adjusted to meet 4.5:1 contrast against the page background or a `.secondary` card fill.
    /// - Parameters:
    ///   - color: The course color, or `nil` to keep the default tint.
    ///   - cardOpacity: The opacity of the `.secondary` card fill behind this view, or `nil` when it sits on the page background.
    func readableCourseTint(_ color: Color?, cardOpacity: Double? = nil) -> some View {
        modifier(ReadableCourseTintModifier(color: color, cardOpacity: cardOpacity))
    }

    /// Sets the foreground to black or white, whichever is more legible on the given background color.
    /// - Parameter background: The color behind this view, or `nil` to leave the foreground unchanged.
    func readableForeground(_ background: Color?) -> some View {
        modifier(ReadableForegroundModifier(background: background))
    }
}
