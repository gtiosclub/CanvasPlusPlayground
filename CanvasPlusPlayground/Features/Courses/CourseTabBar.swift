//
//  CourseTabBar.swift
//  CanvasPlusPlayground
//

import SwiftUI

/// Horizontally scrolling row of a course's Canvas tabs. Home is the current screen; other tabs push their page.
struct CourseTabBar: View {
    let course: Course

    private var pages: [NavigationModel.CoursePage] {
        NavigationModel.CoursePage.available(for: course).filter { $0 != .home }
    }

    private var externalLinks: [CanvasTab] {
        course.tabs.filter { $0.visibility == .public && $0.type == .external }
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                CourseTabCapsule(title: "Home", systemImage: "square.grid.2x2.fill", isSelected: true)
                    .accessibilityAddTraits(.isSelected)

                ForEach(pages, id: \.self) { page in
                    NavigationLink(value: NavigationModel.Destination.coursePage(page, course)) {
                        CourseTabCapsule(title: page.title, systemImage: page.systemImageIcon)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if let pinnedItemType = PinnedItem.PinnedItemType(coursePage: page) {
                            PinButton(itemID: course.id, courseID: course.id, type: pinnedItemType)
                        }
                        NewWindowButton(destination: .coursePage(page, course))
                    }
                }

                ForEach(externalLinks) { link in
                    Link(destination: link.htmlAbsoluteUrl) {
                        CourseTabCapsule(title: link.label, systemImage: "link")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollClipDisabled()
        .scrollIndicators(.hidden)
    }
}

private struct CourseTabCapsule: View {
    let title: String
    let systemImage: String
    var isSelected = false

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule().fill(.tint)
                }
            }
            #if !os(visionOS)
            .compatibleGlassEffect(isInteractive: !isSelected, in: .capsule)
            #endif
    }
}
