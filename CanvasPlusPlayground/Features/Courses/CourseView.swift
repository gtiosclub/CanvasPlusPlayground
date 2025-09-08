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
                NavigationModel.CoursePage(rawValue: tab.label.lowercased())
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

    private var externalCoursePageLinks: [CanvasTab] {
        guard !course.tabs.isEmpty, pickerService == nil else {
            return []
        }

        return course.tabs
            .filter { $0.visibility == .public }
            .filter { $0.type == .external }
    }

    var body: some View {
        @Bindable var navigationModel = navigationModel

        List(selection: $navigationModel.selectedCoursePage) {
            Section {
                ForEach(coursePages, id: \.self) { page in
                    NavigationLink(value: NavigationModel.Destination.coursePage(page, course)) {
                        Label(page.title, systemImage: page.systemImageIcon)
                            .contextMenu(for: FocusWindowInfo(courseID: course.id, coursePage: page))
                    }
                    .tag(page)
                }
            }

            Section("External") {
                ForEach(externalCoursePageLinks) { link in
                    Link(destination: link.htmlAbsoluteUrl) {
                        Label(link.label, systemImage: "link")
                    }
                }
            }
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
        .defaultNavigationDestination(courseID: course.id)
        .openInCanvasToolbarButton(.homepage(course.id))
    }
}
