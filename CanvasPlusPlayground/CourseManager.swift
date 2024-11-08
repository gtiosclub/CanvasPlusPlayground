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
    var prefCourses = Set<Course>()
    var userFavCourses: [Course] {
        courses.filter { prefCourses.contains($0) }
    }
    var userOtherCourses: [Course] {
        courses.filter { !prefCourses.contains($0) }
    }
    
    var enrollments = [Enrollment]()

    func getCourses() async {
        do {
            let courses: [Course] = try await CanvasService.shared.defaultAndFetch(
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
    
    func togglePref(course: Course) {
        if (prefCourses.contains(course)) {
            prefCourses.remove(course)
        } else {
            prefCourses.insert(course)
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
