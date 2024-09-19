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
    var enrollments = [Enrollment]()

    func getCourses() async {
        guard let (data, _) = await CanvasService.shared.fetch(.getCourses(enrollmentState: "active")) else {
            print("Failed to fetch files.")
            return
        }
        
        if let retCourses = try? JSONDecoder().decode([Course].self, from: data) {
            self.courses = retCourses
        } else {
            print("Failed to decode file data.")
        }
    }
    
    func getEnrollments() async {
        guard let (data, _) = await CanvasService.shared.fetch(.getEnrollments) else {
            print("Failed to fetch enrollments")
            return
        }
        
        do {
            enrollments = try JSONDecoder().decode([Enrollment].self, from: data)
        } catch {
            print(error)
        }
    }
}
