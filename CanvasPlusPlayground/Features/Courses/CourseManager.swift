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

    var displayedCourses: [Course] {
        allCourses
            .filter { !($0.isHidden ?? false) }
    }

    var userFavCourses: [Course] {
        allCourses
            .filter { !($0.isHidden ?? false) }
            .filter { $0.isFavorite }
            .sorted { $0.name ?? "" < $1.name ?? "" }
    }

    var userOtherCourses: [Course] {
        allCourses
            .filter { !($0.isHidden ?? false) }
            .filter { !($0.isFavorite) }
            .sorted { $0.name ?? "" < $1.name ?? "" }
    }

    var userHiddenCourses: [Course] {
        allCourses
            .filter { $0.isHidden ?? false }
            .sorted { $0.name ?? "" < $1.name ?? "" }
    }

    func getCourses() async {
        logger.debug("Fetching courses")
        do {
            let courses: [Course] = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getCourses(enrollmentState: "active"),
                onCacheReceive: { cachedCourses in
                    guard let cachedCourses else { return }
                    Task { @MainActor in
                        self.setCourses(cachedCourses)
                    }
                }
            )
            logger.debug("\(courses.map(\.name))")

            await setCourses(courses)
        } catch {
            logger.error("Failed to fetch courses. \(error)")
        }
    }

    @MainActor
    func setCourses(_ courses: [Course]) {
        self.allCourses = courses
    }
}
