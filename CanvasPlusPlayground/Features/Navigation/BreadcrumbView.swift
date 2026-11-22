//
//  BreadcrumbView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 3/30/26.
//



import SwiftUI

struct BreadcrumbView: View {
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(CourseManager.self) private var courseManager

    private struct RootCrumb {
        let title: String
        var systemImage: String?
        let action: () -> Void
    }

    /// Crumbs before the pushed path: "Home", plus the course (and course page) when a course sidebar tab is open.
    private var rootCrumbs: [RootCrumb] {
        let home = RootCrumb(title: "Home", systemImage: "house") { [navigationModel] in
            navigationModel.popToRoot()
        }
        switch navigationModel.selectedTab {
        case .course(let id):
            guard let course = courseManager.course(withID: id) else { return [home] }
            return [
                RootCrumb(title: "Home", systemImage: "house") { [navigationModel] in navigationModel.selectedTab = .dashboard },
                RootCrumb(title: course.displayName) { [navigationModel] in navigationModel.popToRoot() },
            ]
        case let .coursePage(id, page):
            guard let course = courseManager.course(withID: id) else { return [home] }
            return [
                RootCrumb(title: "Home", systemImage: "house") { [navigationModel] in navigationModel.selectedTab = .dashboard },
                RootCrumb(title: course.displayName) { [navigationModel] in navigationModel.selectedTab = .course(id) },
                RootCrumb(title: page.title) { [navigationModel] in navigationModel.popToRoot() },
            ]
        default:
            return [home]
        }
    }

    var body: some View {
        let crumbs = navigationModel.breadcrumbs
        let roots = rootCrumbs
        guard !crumbs.isEmpty || roots.count > 1 else { return AnyView(EmptyView()) }

        return AnyView(
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(roots.enumerated()), id: \.offset) { index, root in
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.quaternary)
                        }
                        BreadcrumbButton(
                            title: root.title,
                            systemImage: root.systemImage,
                            isLast: crumbs.isEmpty && index == roots.count - 1,
                            action: root.action
                        )
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
