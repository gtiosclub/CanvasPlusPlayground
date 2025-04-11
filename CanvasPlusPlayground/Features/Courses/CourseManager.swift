//
//  CourseManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI

@Observable
@MainActor
class CourseManager {
    var allCourses = [Course]()

    /// This list is used in `PeopleCommonView` and `AllAnnouncements`.
    var activeCourses: [Course] {
        allCourses
            .filter { $0.hasActiveEnrollment }
            .sorted { $0.name ?? "" < $1.name ?? "" }
    }

    var favoritedCourses: [Course] {
        allCourses
            .filter { $0.canFavorite && $0.isFavorite }
            .sorted { $0.name ?? "" < $1.name ?? "" }
    }

    var unfavoritedCourses: [Course] {
        allCourses
            .filter { !$0.isFavorite || !$0.canFavorite }
            .sorted { $0.name ?? "" < $1.name ?? "" }
    }

    let courseService = CourseService()

    func getCourses() async {
        LoggerService.main.debug("Fetching courses")
        do {
            self.allCourses = courseService.courseRepository.getCourses(
                enrollmentType: nil,
                enrollmentState: .active,
                excludeBlueprintCourses: false,
                state: [],
                pageConfiguration: .all(perPage: 40)
            )

            self.allCourses = try await courseService.getCourses(
                enrollmentType: nil,
                enrollmentState: .active,
                excludeBlueprintCourses: false,
                state: [],
                pageConfiguration: .all(perPage: 40)
            )
            LoggerService.main.debug("Fetched courses: \(self.allCourses.compactMap(\.name))")
        } catch {
            LoggerService.main.error("Failed to fetch courses. \(error)")
        }
    }
}
