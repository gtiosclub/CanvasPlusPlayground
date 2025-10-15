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

    @State var selectedCoursePage: NavigationModel.CoursePage?

    var body: some View {
        @Bindable var navigationModel = navigationModel

        List(selection: $selectedCoursePage) {
            Section {
                ForEach(coursePages, id: \.self) { page in
                    NavigationLink(value: NavigationModel.Destination.coursePage(page, course)) {
                        Label(page.title, systemImage: page.systemImageIcon)
                    }
                    .contextMenu {
                        NewWindowButton(destination: .coursePage(page, course))
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
        .handleDeepLinks(for: course.id)
        .scrollContentBackground(.hidden)
        .courseGradientBackground(
            courses: [course],
            isActive: course.rgbColors != nil,
            backgroundStyle: .grouped,
            showIcon: true
        )
        .onAppear {
            selectedCoursePage = nil
        }
        .tint(course.rgbColors?.color)
        .customizeCourseMenu(course: course, placement: .toolbar)
#if os(iOS)
        .listStyle(.insetGrouped)
#else
        .listStyle(.sidebar)
#endif
        .navigationTitle(course.displayName)
        .openInCanvasToolbarButton(.homepage(course.id))
    }
}
