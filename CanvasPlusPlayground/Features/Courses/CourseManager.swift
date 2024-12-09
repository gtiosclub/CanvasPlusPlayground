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
        courses.filter { $0.isFavorite ?? false }.sorted { $0.name ?? "" < $1.name ?? "" }
    }

    var userOtherCourses: [Course] {
        courses.filter { !($0.isFavorite ?? false) }.sorted { $0.name ?? "" < $1.name ?? "" }
    }
    
    var enrollments = [Enrollment]()

    func getCourses() async {
        do {
            let courses: [Course] = try await CanvasService.shared.loadAndSync(
                .getCourses(enrollmentState: "active"),
                onCacheReceive: { cachedCourses in
                   guard let cachedCourses else { return }
                   self.courses = cachedCourses
                }
            )

            self.courses = courses
        } catch {
            print("Failed to fetch files. \(error)")
        }
    }
    
    func getEnrollments() async {
        do {
            let enrollments: [Enrollment] = try await CanvasService.shared.fetch(.getCourses(enrollmentState: "active"))
            self.enrollments = enrollments
        } catch {
            print("Failed to fetch enrollments. \(error)")
        }
    }
}
