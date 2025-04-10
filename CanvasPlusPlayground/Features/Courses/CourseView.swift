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

    let course: Course

    private var tabLabels: [String] {
        course.tabs.map(\.label).compactMap { $0 }
    }

    private var coursePages: [NavigationModel.CoursePage] {
        guard !course.tabs.isEmpty else {
            return []
        }

        let availableTabs = Set<NavigationModel.CoursePage>(
            course.tabs.compactMap { tab in
                return NavigationModel.CoursePage(rawValue: tab.label.lowercased())
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
            NavigationLink(value: NavigationModel.Destination.coursePage(page)) {
                Label(page.title, systemImage: page.systemImageIcon)
            }
            .tag(page)
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
            destination.destinationView(for: course)
        }
    }
}
