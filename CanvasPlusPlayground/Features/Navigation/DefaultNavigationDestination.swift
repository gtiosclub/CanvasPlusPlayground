//  DefaultNavigationDestination.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 9/4/25.
//

import SwiftUI

extension View {
    /// Adds the default navigation destination logic for NavigationModel.Destination.
    /// Also keeps the breadcrumb trail in sync with the navigation path.
    func defaultNavigationDestination() -> some View {
        self.modifier(DefaultNavigationDestinationModifier())
    }
}

private struct DefaultNavigationDestinationModifier: ViewModifier {
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(CourseManager.self) private var courseManager

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: NavigationModel.Destination.self) { destination in
                let course = contextCourse(for: destination)

                destination.destinationView()
                    .toolbarBackground(.hidden, for: .automatic)
                    .scrollContentBackground(.hidden)
                    .courseGradientBackground(
                        courses: course.map { [$0] } ?? [],
                        isActive: course != nil
                    )
                    .tint(course?.rgbColors?.color)
                    .onAppear {
                        navigationModel.recordDestination(destination)
                    }
                    .safeAreaInset(edge: .top, spacing: 0) {
                        BreadcrumbView()
                    }
            }
            .onChange(of: navigationModel.navigationPath.count) { oldCount, newCount in
                if newCount < oldCount {
                    navigationModel.trimBreadcrumbs(to: newCount)
                }
            }
    }

    /// Resolves the course a destination belongs to:
    /// 1. The destination itself carries a Course (e.g. `.course`, `.coursePage`).
    /// 2. The destination's content carries a course ID — look it up in CourseManager
    ///    (e.g. an Assignment opened directly from To-Dos).
    /// 3. Walk back through the breadcrumb trail to inherit the ancestor's course
    ///    (e.g. an Assignment pushed from within a Course view).
    private func contextCourse(for destination: NavigationModel.Destination) -> Course? {
        if let course = destination.associatedCourse { return course }
        if let id = destination.associatedCourseID,
           let course = courseManager.course(withID: id) {
            return course
        }
        return navigationModel.breadcrumbs
            .reversed()
            .lazy
            .compactMap(\.associatedCourse)
            .first
    }
}
