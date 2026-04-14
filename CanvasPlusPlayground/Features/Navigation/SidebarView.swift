//
//  SidebarView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 4/13/26.
//

import SwiftUI

struct SidebarView: View {
    @Environment(CourseManager.self) private var courseManager

    @Binding var selectedTab: NavigationModel.Tab?
    @Binding var expandedCourses: Set<Course.ID>
    @State private var visiblePages: [Course.ID: Int] = [:]
    @State private var revealGeneration: [Course.ID: Int] = [:]

    var body: some View {
        List(selection: $selectedTab) {
            NavigationLink(value: NavigationModel.Tab.dashboard) {
                Label("Dashboard", systemImage: "rectangle.grid.2x2.fill")
            }

            if !courseManager.favoritedCourses.isEmpty {
                Section("Favorited Courses") {
                    ForEach(courseManager.favoritedCourses, id: \.id) { course in
                        courseDisclosure(course)
                    }
                }
            }

            if !courseManager.unfavoritedCourses.isEmpty {
                Section("Other Courses") {
                    ForEach(courseManager.unfavoritedCourses, id: \.id) { course in
                        courseDisclosure(course)
                    }
                }
            }
        }
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 240, ideal: 260)
        #endif
        .listStyle(.sidebar)
        .navigationTitle("Home")
    }

    @ViewBuilder
    private func courseDisclosure(_ course: Course) -> some View {
        let expanded = expandedCourses.contains(course.id)

        HStack {
            CourseListCell(course: course)
            Spacer(minLength: 0)
            Button {
                if expanded {
                    visiblePages[course.id] = 0
                    expandedCourses.remove(course.id)
                } else {
                    expandedCourses.insert(course.id)
                    visiblePages[course.id] = 0
                    revealPages(for: course)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(expanded ? 90 : 0))
                    .animation(.spring(duration: 0.3, bounce: 0.2), value: expanded)
                    .contentShape(Rectangle())
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)
        }
        .tag(NavigationModel.Tab.course(course.id))

        if expanded {
            let pages = NavigationModel.CoursePage.available(for: course)
            let revealed = visiblePages[course.id] ?? 0
            ForEach(Array(pages.enumerated()), id: \.element) { index, page in
                NavigationLink(value: NavigationModel.Tab.coursePage(course.id, page)) {
                    Label(page.title, systemImage: page.systemImageIcon)
                        .padding(.leading)
                }
                .id("\(course.id)-\(page.rawValue)")
                .opacity(index < revealed ? 1 : 0)
                .offset(y: index < revealed ? 0 : -10)
                .animation(.spring(duration: 0.2, bounce: 0.15), value: index < revealed)
            }
        }
    }

    private func revealPages(for course: Course) {
        let gen = (revealGeneration[course.id] ?? 0) + 1
        revealGeneration[course.id] = gen
        visiblePages[course.id] = 0

        let count = NavigationModel.CoursePage.available(for: course).count
        for i in 1...count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06 + Double(i) * 0.018) {
                guard revealGeneration[course.id] == gen else { return }
                visiblePages[course.id] = i
            }
        }
    }
}
