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

    @State private var tabsManager = CourseTabsManager()
    @State private var isLoadingTabs = false

    let course: Course

    init(course: Course) {
        self.course = course
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
            var isAvailable = availableTabs.contains($0) || NavigationModel.CoursePage.requiredTabs.contains($0)

            if let pickerService {
                isAvailable = isAvailable && pickerService.supportedPickerViews.contains($0)
            }

            return isAvailable
        }
    }

    var body: some View {
        @Bindable var navigationModel = navigationModel

        List(coursePages, id: \.self, selection: $navigationModel.selectedCoursePage) { page in
            NavigationLink(value: NavigationModel.Destination.coursePage(page, course)) {
                Label(page.title, systemImage: page.systemImageIcon)
            }
            .tag(page)
        }
        .task(id: course.id) {
            await fetchTabs()
        }
        .onAppear {
            navigationModel.selectedCoursePage = nil
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.sidebar)
        #endif
        .tint(course.rgbColors?.color)
        .navigationTitle(course.displayName)
        .navigationDestination(for: NavigationModel.Destination.self) { destination in
            destination.destinationView()
                .environment(tabsManager)
        }
        .disabled(isLoadingTabs)
    }

    private func fetchTabs() async {
        isLoadingTabs = true
        await tabsManager.fetchTabs(course: course)
        isLoadingTabs = false
    }
}
