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
        let pages = NavigationModel.CoursePage.available(for: course)
        guard let pickerService else { return pages }
        return pages.filter { pickerService.supportedPickerViews.contains($0) }
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
                        if let pinnedItemType = PinnedItem.PinnedItemType(coursePage: page) {
                            PinButton(
                                itemID: course.id,
                                courseID: course.id,
                                type: pinnedItemType
                            )
                        }
                        NewWindowButton(destination: .coursePage(page, course))
                    }
                    .swipeActions(edge: .leading) {
                        if let pinnedItemType = PinnedItem.PinnedItemType(coursePage: page) {
                            PinButton(
                                itemID: course.id,
                                courseID: course.id,
                                type: pinnedItemType
                            )
                        }
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
