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
    let showIcon: Bool

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
                        ZStack(alignment: .topTrailing) {
                            DashboardMeshGradient(
                                colors: DashboardGradientColors
                                    .getColors(from: courses)
                            )

                            if showIcon, let course = courses.first {
                                CourseIcon(
                                    symbolName: course.displaySymbol
                                )
                            }
                        }
                        .frame(height: 400)

                        Spacer()
                    }
                    .ignoresSafeArea()
                }
            }
    }
}

private struct CourseIcon: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    let symbolName: String

    @State private var symbolToggle = false

    var body: some View {
        GeometryReader { geo in
            let xFactor: CGFloat = horizontalSizeClass == .compact ? 100 : 200
            let yFactor: CGFloat = 0.25

            Image(systemName: symbolName)
                .symbolEffect(.breathe, value: symbolToggle)
                .opacity(0.2)
                .font(.system(size: 125))
                .position(
                    x: geo.size.width - xFactor,
                    y: geo.size.height * yFactor
                )
        }
        .onAppear {
            withAnimation(.spring) {
                symbolToggle.toggle()
            }
        }
    }
}

extension View {
    func courseGradientBackground(
        courses: [Course],
        isActive: Bool = true,
        backgroundStyle: DashboardGradientBackgroundStyle = .default,
        showIcon: Bool = false
    ) -> some View {
        modifier(
            CourseGradientBackgroundModifier(
                courses: courses,
                isActive: isActive,
                backgroundStyle: backgroundStyle,
                showIcon: showIcon
            )
        )
    }
}
