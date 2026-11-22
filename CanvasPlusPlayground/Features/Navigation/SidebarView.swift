//
//  SidebarView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 4/13/26.
//

import SwiftUI

struct SidebarView: View {
    @Environment(CourseManager.self) private var courseManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var selectedTab: NavigationModel.Tab?
    @Binding var expandedCourses: Set<Course.ID>

    var body: some View {
        List(selection: $selectedTab) {
            NavigationLink(value: NavigationModel.Tab.dashboard) {
                Label("Dashboard", systemImage: "rectangle.grid.2x2.fill")
                    .font(SidebarMetrics.courseFont)
            }

            if !courseManager.favoritedCourses.isEmpty {
                Section {
                    ForEach(courseManager.favoritedCourses, id: \.id) { course in
                        courseRows(course)
                    }
                } header: {
                    SidebarSectionHeader(title: "Classes")
                }
            }

            if !courseManager.unfavoritedCourses.isEmpty {
                Section {
                    ForEach(courseManager.unfavoritedCourses, id: \.id) { course in
                        courseRows(course)
                    }
                } header: {
                    SidebarSectionHeader(title: courseManager.favoritedCourses.isEmpty ? "Classes" : "Other Classes")
                }
            }
        }
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 240, ideal: 270)
        #endif
        .listStyle(.sidebar)
        #if os(iOS)
        .environment(\.defaultMinListRowHeight, 38)
        #endif
        .navigationTitle("Home")
    }

    @ViewBuilder
    private func courseRows(_ course: Course) -> some View {
        let expanded = expandedCourses.contains(course.id)

        SidebarCourseRow(course: course, isExpanded: expanded) {
            toggle(course)
        }
        .tag(NavigationModel.Tab.course(course.id))
        .listRowSeparator(.hidden)

        if expanded {
            let pages = NavigationModel.CoursePage.available(for: course)
            ForEach(Array(pages.enumerated()), id: \.element) { index, page in
                NavigationLink(value: NavigationModel.Tab.coursePage(course.id, page)) {
                    SidebarPageRow(page: page, index: index)
                }
                .id(NavigationModel.Tab.coursePage(course.id, page))
                .listRowSeparator(.hidden)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
    }

    private func toggle(_ course: Course) {
        let animation: Animation = reduceMotion ? .easeInOut(duration: 0.2) : SidebarMetrics.expandAnimation
        withAnimation(animation) {
            if expandedCourses.contains(course.id) {
                expandedCourses.remove(course.id)
            } else {
                expandedCourses.insert(course.id)
            }
        }
    }
}

// MARK: - Rows

enum SidebarMetrics {
    /// A soft, slightly bouncy spring for opening and closing a course.
    static let expandAnimation = Animation.spring(response: 0.42, dampingFraction: 0.74)

    static let dotSize: CGFloat = 14
    static let dotSpacing: CGFloat = 10

    #if os(macOS)
    static let courseFont = Font.system(size: 13, weight: .medium)
    static let pageFont = Font.system(size: 12)
    static let pageIconFont = Font.system(size: 10, weight: .medium)
    #else
    static let courseFont = Font.body.weight(.medium)
    static let pageFont = Font.subheadline
    static let pageIconFont = Font.caption
    #endif
}

/// "Classes": a quiet header like the refined design's.
private struct SidebarSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(.footnote, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(nil)
    }
}

/// A course: its color as a dot, its name, and a chevron that opens its pages.
struct SidebarCourseRow: View {
    let course: Course
    let isExpanded: Bool
    let onToggle: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: SidebarMetrics.dotSpacing) {
            Circle()
                .fill(course.sidebarColor.gradient)
                .frame(width: SidebarMetrics.dotSize, height: SidebarMetrics.dotSize)
                .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 0.5))
                .scaleEffect(isExpanded ? 1.08 : 1)

            Text(course.displayName)
                .font(SidebarMetrics.courseFont)
                .fontWeight(isExpanded ? .semibold : .medium)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 4)

            Button(action: onToggle) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isHovered || isExpanded ? .secondary : .tertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "Collapse \(course.displayName)" : "Expand \(course.displayName)")
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isExpanded)
        .customizeCourseMenu(course: course, placement: .contextMenu)
    }
}

/// A course page under its course: indented past the dot, smaller and quieter. Rows cascade in
/// one after another when the course opens.
private struct SidebarPageRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let page: NavigationModel.CoursePage
    let index: Int

    @State private var shown = false

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: page.systemImageIcon)
                .font(SidebarMetrics.pageIconFont)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(page.title)
                .font(SidebarMetrics.pageFont)
                .foregroundStyle(.secondary)
        }
        .padding(.leading, SidebarMetrics.dotSize + SidebarMetrics.dotSpacing - 4)
        .padding(.vertical, 1)
        .opacity(shown ? 1 : 0)
        .offset(y: shown ? 0 : -6)
        .onAppear {
            guard !shown else { return }
            if reduceMotion {
                shown = true
            } else {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.68).delay(Double(index) * 0.025)) { shown = true }
            }
        }
    }
}

// MARK: - Course color

extension Course {
    /// Soft colors from the design, used when Canvas has no color for a course.
    private static let sidebarPalette: [Color] = [
        Color(red: 0.53, green: 0.81, blue: 0.69),  // mint
        Color(red: 0.56, green: 0.70, blue: 0.83),  // blue
        Color(red: 0.61, green: 0.56, blue: 0.84),  // purple
        Color(red: 0.80, green: 0.55, blue: 0.80),  // pink
        Color(red: 0.77, green: 0.79, blue: 0.56),  // olive
        Color(red: 0.96, green: 0.69, blue: 0.51),  // peach
    ]

    /// The course's own color, or a stable one from the palette so every course has a dot.
    var sidebarColor: Color {
        if let color = rgbColors?.color { return color }
        let hash = id.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7fffffff }
        return Self.sidebarPalette[hash % Self.sidebarPalette.count]
    }
}
