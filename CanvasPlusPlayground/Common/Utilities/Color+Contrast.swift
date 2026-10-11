//
//  Color+Contrast.swift
//  CanvasPlusPlayground
//
//  Created by Kareem on 10/10/26.
//

import SwiftUI

/// WCAG 2.x relative luminance and contrast ratio math.
enum WCAGContrast {
    /// The minimum contrast ratio for normal-size text (WCAG 1.4.3, level AA).
    static let minimumTextRatio = 4.5

    /// Computes the relative luminance of a color from its linear sRGB components.
    /// - Parameters:
    ///   - linearRed: The linear red component. Values outside `0...1` are clamped.
    ///   - linearGreen: The linear green component. Values outside `0...1` are clamped.
    ///   - linearBlue: The linear blue component. Values outside `0...1` are clamped.
    /// - Returns: The relative luminance, from `0` (black) to `1` (white).
    static func relativeLuminance(linearRed: Double, linearGreen: Double, linearBlue: Double) -> Double {
        0.2126 * clamp(linearRed) + 0.7152 * clamp(linearGreen) + 0.0722 * clamp(linearBlue)
    }

    /// Computes the contrast ratio between two relative luminances.
    /// - Parameters:
    ///   - first: The relative luminance of one color.
    ///   - second: The relative luminance of the other color.
    /// - Returns: The contrast ratio, from `1` (no contrast) to `21` (black on white). Argument order does not matter.
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

    func body(content: Content) -> some View {
        content.tint(
            color?.readable(
                against: .courseContentBackground(for: environment.colorScheme),
                in: environment
            )
        )
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
    /// The WCAG relative luminance of this color, ignoring opacity.
    var relativeLuminance: Double {
        WCAGContrast.relativeLuminance(
            linearRed: Double(linearRed),
            linearGreen: Double(linearGreen),
            linearBlue: Double(linearBlue)
        )
    }

    /// Computes the WCAG contrast ratio between this color and another.
    /// - Parameter other: The color to compare against.
    /// - Returns: The contrast ratio, from `1` to `21`.
    func contrastRatio(with other: Color.Resolved) -> Double {
        WCAGContrast.contrastRatio(relativeLuminance, other.relativeLuminance)
    }
}

extension Color {
    private static let readableMixSteps = 20

    /// Picks black or white, whichever contrasts more with this color, for content drawn on top of it.
    /// - Parameter environment: The environment used to resolve this color, such as the current color scheme.
    /// - Returns: `.black` or `.white`. Always meets at least 4.5:1 against any opaque color.
    func accessibleForeground(in environment: EnvironmentValues) -> Color {
        let luminance = resolve(in: environment).relativeLuminance
        let whiteRatio = WCAGContrast.contrastRatio(1, luminance)
        let blackRatio = WCAGContrast.contrastRatio(0, luminance)
        return whiteRatio >= blackRatio ? .white : .black
    }

    /// Adjusts this color so it stays legible when drawn as text or tint on a background.
    ///
    /// If this color already meets `minimumRatio`, it is returned unchanged. Otherwise it is mixed in
    /// small steps toward black or white, whichever reaches the ratio with the smaller change.
    /// - Parameters:
    ///   - background: The color the result will be drawn on.
    ///   - environment: The environment used to resolve both colors, such as the current color scheme.
    ///   - minimumRatio: The contrast ratio the result must meet. Defaults to 4.5, the WCAG AA text minimum.
    /// - Returns: A color that meets `minimumRatio` against `background`, or black or white
    ///   (whichever contrasts more) when no color can meet it.
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

    /// The background that course-tinted content is checked against for a color scheme.
    /// - Parameter colorScheme: The color scheme the background is drawn in.
    /// - Returns: The system grouped background, or the window background on macOS.
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
}

extension View {
    /// Tints this view with a course color, adjusted to meet 4.5:1 contrast against the page background.
    /// - Parameter color: The course color, or `nil` to keep the default tint.
    func readableCourseTint(_ color: Color?) -> some View {
        modifier(ReadableCourseTintModifier(color: color))
    }

    /// Sets the foreground to black or white, whichever is more legible on the given background color.
    /// - Parameter background: The color behind this view, or `nil` to leave the foreground unchanged.
    func readableForeground(_ background: Color?) -> some View {
        modifier(ReadableForegroundModifier(background: background))
    }
}
