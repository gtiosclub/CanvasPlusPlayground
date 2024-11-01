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
        /*
        guard let (data, _) = try? await CanvasService.shared.fetch(.getCourses(enrollmentState: "active")) else {
            print("Failed to fetch files.")
            return
        }
        
        if let retCourses = try? JSONDecoder().decode([Course].self, from: data) {
            self.courses = retCourses
        } else {
            print("Failed to decode file data.")
        }*/
        
        do {
            let courses: [Course] = try await CanvasService.shared.fetch(.getCourses(enrollmentState: "active"))
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
        /*
        guard let (data, _) = try? await CanvasService.shared.fetchResponse(.getEnrollments) else {
            print("Failed to fetch enrollments")
            return
        }
        
        do {
            enrollments = try JSONDecoder().decode([Enrollment].self, from: data)
        } catch {
            print(error)
        }*/
        
        do {
            let enrollments: [Enrollment] = try await CanvasService.shared.fetch(.getCourses(enrollmentState: "active"))
            self.enrollments = enrollments
        } catch {
            print("Failed to fetch enrollments. \(error)")
        }
    }
}
