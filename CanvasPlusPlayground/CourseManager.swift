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
    var submissions = [Submission]()
    var syllabus = [SyllabusUpdate]()

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
    
    func getSubmissions(courseId: Int?) async {
        guard let courseId else {
            print("getSubmission failed: courseId is nil")
            return
        }
        guard let (data, _) = await CanvasService.shared.fetch(.getSubmissions(courseId: courseId)) else {
            print("Failed to fetch submissions")
            return
        }
        
        do {
            submissions = try JSONDecoder().decode([Submission].self, from: data)
        } catch {
            print(error)
        }
    }
    
    func getSyllabus(courseId: Int?) async {
        guard let courseId else {
            print("getSubmission failed: courseId is nil")
            return
        }
        guard let (data, _) = await CanvasService.shared.fetch(.getSyllabus(courseId: courseId)) else {
            print("Failed to fetch submissions")
            return
        }
        
        do {
            syllabus = try JSONDecoder().decode([SyllabusUpdate].self, from: data)
        } catch {
            print(error)
        }
    }
}
