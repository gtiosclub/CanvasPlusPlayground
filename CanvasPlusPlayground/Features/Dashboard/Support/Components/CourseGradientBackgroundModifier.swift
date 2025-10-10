//
//  CourseGradientBackgroundModifier.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/10/25.
//

import SwiftUI

enum DashboardGradientBackgroundStyle {
    case `default`
    case grouped
}

private struct CourseGradientBackgroundModifier: ViewModifier {
    let courses: [Course]
    let isActive: Bool
    let backgroundStyle: DashboardGradientBackgroundStyle

    public func body(content: Content) -> some View {
        content
            .background {
                Group {
                    switch backgroundStyle {
                    case .default:
                        #if os(iOS)
                        Color(uiColor: .systemBackground)
                        #elseif os(macOS)
                        Color(nsColor: .windowBackgroundColor)
                        #endif
                    case .grouped:
                        #if os(iOS)
                        Color(uiColor: .systemGroupedBackground)
                        #elseif os(macOS)
                        Color(nsColor: .windowBackgroundColor)
                        #endif
                    }
                }
                .ignoresSafeArea()

                if isActive {
                    VStack(spacing: 0) {
                        DashboardMeshGradient(
                            colors: DashboardGradientColors
                                .getColors(from: courses)
                        )
                        .frame(height: 400)
                        Spacer()
                    }
                    .ignoresSafeArea()
                }
            }
    }
}

extension View {
    func courseGradientBackground(
        courses: [Course],
        isActive: Bool = true,
        backgroundStyle: DashboardGradientBackgroundStyle = .default
    ) -> some View {
        modifier(
            CourseGradientBackgroundModifier(
                courses: courses,
                isActive: isActive,
                backgroundStyle: backgroundStyle
            )
        )
    }
}
