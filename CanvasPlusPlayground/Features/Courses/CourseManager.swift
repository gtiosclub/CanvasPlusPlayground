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
    var userCourses: [Course] {
        allCourses
            .filter { !($0.isHidden ?? false) }
            .sorted { $0.name ?? "" < $1.name ?? "" }
    }

    var hiddenCourses: [Course] {
        allCourses
            .filter { $0.isHidden ?? false }
            .sorted { $0.name ?? "" < $1.name ?? "" }
    }

    let courseService = CourseService()

    func getCourses() async {
        LoggerService.main.debug("Fetching courses")
        do {
            self.allCourses = courseService.courseRepository.getCourses(
                enrollmentType: nil,
                enrollmentState: nil,
                excludeBlueprintCourses: false,
                state: [],
                pageConfiguration: .all(perPage: 40)
            )

            self.allCourses = try await courseService.getCourses(
                enrollmentType: nil,
                enrollmentState: nil,
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
