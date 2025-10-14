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
    var activeCourses = [Course]()

    var favoritedCourses: [Course] {
        activeCourses
            .filter { $0.canFavorite && $0.isFavorite }
            .sorted { $0.name ?? "" < $1.name ?? "" }
    }

    var unfavoritedCourses: [Course] {
        activeCourses
            .filter { !$0.isFavorite || !$0.canFavorite }
            .sorted { $0.name ?? "" < $1.name ?? "" }
    }

    let courseService = CourseService()

    func getCourses() async {
        LoggerService.main.debug("Fetching courses")
        do {
            self.activeCourses = courseService.courseRepository.getCourses(
                enrollmentType: nil,
                enrollmentState: .active,
                excludeBlueprintCourses: false,
                state: [],
                pageConfiguration: .all(perPage: 40)
            )

            self.activeCourses = try await courseService.getCourses(
                enrollmentType: nil,
                enrollmentState: .active,
                excludeBlueprintCourses: false,
                state: [],
                pageConfiguration: .all(perPage: 40)
            )
            LoggerService.main.debug("Fetched courses: \(self.activeCourses.compactMap(\.name))")
        } catch {
            LoggerService.main.error("Failed to fetch courses. \(error)")
        }
    }

    func course(withID id: Course.ID) -> Course? {
        activeCourses.first { $0.id == id }
    }
}
