//
//  CourseView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/8/24.
//

import SwiftUI

struct CourseView: View {
    @Environment(PickerService.self) private var pickerService: PickerService?
    @Environment(NavigationModel.self) private var navigationModel
    @State private var tabsManager: CourseTabsManager
    let course: Course

    init(course: Course) {
        self.course = course
        self._tabsManager = State(wrappedValue: CourseTabsManager(course: course))
    }

    private var coursePages: [NavigationModel.CoursePage] {
        guard !tabsManager.tabs.isEmpty else {
                return []
            }

        let availableTabs = Set<NavigationModel.CoursePage>(
            tabsManager.tabs.compactMap { tab in
                guard let label = tab.label else { return nil }
                return NavigationModel.CoursePage(rawValue: label.lowercased())
            }
        )

        return NavigationModel.CoursePage.allCases.filter {
            availableTabs.contains($0) || NavigationModel.CoursePage.requiredTabs.contains($0)
        }
    }

    var body: some View {
        @Bindable var navigationModel = navigationModel

        List(coursePages, id: \.self, selection: $navigationModel.selectedCoursePage) { page in
            NavigationLink(value: NavigationModel.Destination.coursePage(page)) {
                Label(page.title, systemImage: page.systemImageIcon)
            }
            .tag(page)
        }
        .onAppear {
            navigationModel.selectedCoursePage = nil
            Task {
                await tabsManager.fetchTabs()
            }
        }
        .onChange(of: course) { _, newCourse in
            tabsManager = CourseTabsManager(course: newCourse)
            Task {
                await tabsManager.fetchTabs()
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.sidebar)
        #endif
        .tint(course.rgbColors?.color)
        .navigationTitle(course.displayName)
        .navigationDestination(for: NavigationModel.Destination.self) { destination in
            destination.destinationView(for: course)
        }
    }
}
