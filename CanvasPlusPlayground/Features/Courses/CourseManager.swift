//
//  CourseManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI

@Observable
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
            let courses = try await courseService.getCourses(
                enrollmentType: nil,
                enrollmentState: .active,
                excludeBlueprintCourses: false,
                state: [],
                pageConfiguration: .all(perPage: 30)
            )
            LoggerService.main.debug("\(courses.map(\.name))")

            await setCourses(courses)
        } catch {
            LoggerService.main.error("Failed to fetch courses. \(error)")
        }
    }

    @MainActor
    func setCourses(_ courses: [Course]) {
        self.allCourses = courses
    }
}
