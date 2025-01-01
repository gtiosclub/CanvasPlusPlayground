//
//  CourseManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI

@Observable
class CourseManager {
    var courses = [Course]()

    var userFavCourses: [Course] {
        courses.filter { $0.isFavorite }.sorted { $0.name ?? "" < $1.name ?? "" }
    }

    var userOtherCourses: [Course] {
        courses.filter { !($0.isFavorite) }.sorted { $0.name ?? "" < $1.name ?? "" }
    }

    func getCourses() async {
        print("Fetching courses")
        do {
            let courses: [Course] = try await CanvasService.shared.loadAndSync(
                CanvasRequest.getCourses(enrollmentState: "active"),
                onCacheReceive: { cachedCourses in
                    guard let cachedCourses else { return }
                    setCourses(cachedCourses)
                }
            )
            print(courses.map(\.name))

            setCourses(courses)
        } catch {
            print("Failed to fetch courses. \(error)")
        }
    }

    func setCourses(_ courses: [Course]) {
        DispatchQueue.main.sync {
            self.courses = courses
        }
    }
}
