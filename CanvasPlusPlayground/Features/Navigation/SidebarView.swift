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
            #if os(macOS)
            SidebarQuickLinks()
                .padding(.bottom, 12)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                .listRowSeparator(.hidden)
                .selectionDisabled()
            #endif

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

#if os(macOS)
/// 2x2 grid of the Dashboard's global pages (same destinations and colors as its navigation capsules).
private struct SidebarQuickLinks: View {
    @Environment(NavigationModel.self) private var navigationModel

    private let links: [(title: String, systemImage: String, tint: Color, destination: NavigationModel.Destination)] = [
        ("Announcements", "bubble.fill", .blue, .allAnnouncements),
        ("Calendar", "calendar", .purple, .allCalendar),
        ("Pinned", "pin.fill", .orange, .pinnedItems),
        ("To-Do", "list.bullet", .red, .allToDos),
    ]

    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow { tile(links[0]); tile(links[1]) }
            GridRow { tile(links[2]); tile(links[3]) }
        }
    }

    private func tile(_ link: (title: String, systemImage: String, tint: Color, destination: NavigationModel.Destination)) -> some View {
        Button {
            navigationModel.selectedTab = .dashboard
            guard navigationModel.breadcrumbs != [link.destination] else { return }
            navigationModel.popToRoot()
            // Push after the pop lands: swapping the top page in one update leaves NavigationStack blank.
            Task { @MainActor in navigationModel.push(link.destination) }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: link.systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(link.tint, in: .circle)
                Text(link.title)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: .rect(cornerRadius: 10))
            .contentShape(.rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
#endif
