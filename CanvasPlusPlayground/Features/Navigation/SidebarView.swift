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
                withAnimation(.easeInOut(duration: 0.45)) {
                    if expanded {
                        expandedCourses.remove(course.id)
                    } else {
                        expandedCourses.insert(course.id)
                    }
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
            ForEach(NavigationModel.CoursePage.available(for: course), id: \.self) { page in
                NavigationLink(value: NavigationModel.Tab.coursePage(course.id, page)) {
                    Label(page.title, systemImage: page.systemImageIcon)
                        .padding(.leading)
                }
                .id(NavigationModel.Tab.coursePage(course.id, page))
            }
        }
    }

}
