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
    let edge: VerticalEdge

    /// Whether any course has custom colors that should override the global gradient.
    private var hasCustomColors: Bool {
        courses.contains { $0.rgbColors != nil }
    }

    public func body(content: Content) -> some View {
        if isActive && hasCustomColors {
            // Course has custom colors — paint an opaque background with the course gradient.
            content
                .scrollContentBackground(.hidden)
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

                    VStack(spacing: 0) {
                        if edge == .bottom {
                            Spacer()
                        }

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

                        if edge == .top {
                            Spacer()
                        }
                    }
                    .ignoresSafeArea()
                }
        } else {
            // No custom colors — stay transparent so the global gradient shows through.
            content
                .scrollContentBackground(.hidden)
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
        showIcon: Bool = false,
        edge: VerticalEdge = .top
    ) -> some View {
        modifier(
            CourseGradientBackgroundModifier(
                courses: courses,
                isActive: isActive,
                backgroundStyle: backgroundStyle,
                showIcon: showIcon,
                edge: edge
            )
        )
    }
}

private struct GlobalAppBackgroundModifier: ViewModifier {
    let courses: [Course]

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background {
                ZStack {
                    #if os(iOS)
                    Color(uiColor: .systemBackground)
                    #elseif os(macOS)
                    Color(nsColor: .windowBackgroundColor)
                    #endif

                    DashboardMeshGradient(
                        colors: DashboardGradientColors.getColors(from: courses)
                    )
                }
                .ignoresSafeArea()
            }
    }
}

extension View {
    func globalAppBackground(courses: [Course]) -> some View {
        modifier(GlobalAppBackgroundModifier(courses: courses))
    }
}
