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
            let courses: [Course] = try await CanvasService.shared.defaultAndFetch(
                .getCourses(enrollmentState: "active"),
                onCacheReceive: { cachedCourses in
                   guard let cachedCourses else { return }
                   self.courses = cachedCourses
                }
            )

            self.courses = courses
            
            //prepare()

        } catch {
            print("Failed to fetch courses. \(error)")
        }
    }
    
    func prepare() {
        Task.detached(priority: .background) {
            await withTaskGroup(of: Void.self) { group in
                let prepares: [(Course) async -> Void] = [
                    self.preparePeople
                ]
                
                for course in self.courses {
                    for prepare in prepares {
                        group.addTask(priority: .low) {
                            await prepare(course)
                        }
                    }
                }
                
            }
        }
    }
    
    func preparePeople(for course: Course) async {
        do {
            let enrollments: [Enrollment] = try await CanvasService.shared.defaultAndFetch(
                .getPeople(courseId: course.id),
                onCacheReceive: { _ in}
            )
            print("Done fetching people in \(#function) for \(course.id). \(enrollments.count)")
        } catch {
            print("Failed to fetch people in \(#function). \(error)")
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
