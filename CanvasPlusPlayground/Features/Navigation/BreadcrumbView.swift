//
//  BreadcrumbView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 3/30/26.
//



import SwiftUI

struct BreadcrumbView: View {
    @Environment(NavigationModel.self) private var navigationModel

    var body: some View {
        let crumbs = navigationModel.breadcrumbs
        guard !crumbs.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    // Root "Home" crumb
                    BreadcrumbButton(
                        title: "Home",
                        systemImage: "house",
                        isLast: false
                    ) {
                        navigationModel.popToRoot()
                    }

                    ForEach(Array(crumbs.enumerated()), id: \.offset) { index, crumb in
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.quaternary)

                        let isLast = index == crumbs.count - 1

                        BreadcrumbButton(
                            title: crumb.displayTitle,
                            isLast: isLast
                        ) {
                            navigationModel.popToIndex(index)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(.ultraThinMaterial, in: .capsule)
            .overlay {
                Capsule()
                    .strokeBorder(.separator, lineWidth: 0.5)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        )
    }
}

private struct BreadcrumbButton: View {
    let title: String
    var systemImage: String?
    let isLast: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Group {
                if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
            .font(.callout)
            .fontDesign(.rounded)
            .fontWeight(isLast ? .semibold : .regular)
            .foregroundStyle(isLast ? .primary : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering && !isLast ? AnyShapeStyle(.secondary.opacity(0.15)) : AnyShapeStyle(.clear))
            }
        }
        .buttonStyle(.plain)
        .disabled(isLast)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
