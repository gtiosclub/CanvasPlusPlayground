//
//  PeopleManager.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 9/22/24.
//

import SwiftUI

@Observable
class PeopleManager {
    private let courseID: Int?
    var enrollments = [Enrollment]()
    var users = [User] ()
    var courses = [Course]()

    init(courseID: Int?) {
        self.courseID = courseID
        self.enrollments = []
        self.users = []
    }
    
    func fetchCurrentCoursePeople() async {
        let enrollments = await fetchPeopleWith(courseID: self.courseID!)
        self.enrollments = enrollments

        for enrollment in self.enrollments {
            if let user = enrollment.user {
                self.users.append(user)
            }
        }
    }

    func fetchPeopleWith(courseID: Int) async -> ([Enrollment]) {
        guard let (data, _) = try? await CanvasService.shared.fetch(.getPeople(courseId: courseID, bookmark: "")) else {
            print("Failed to fetch files.")
            return [];
        }
        
        do {
            let enrollments = try JSONDecoder().decode([Enrollment].self, from: data)
            return enrollments
            
            // TODO: continue to query for next page and append to our lists
            
        } catch {
            print(error)
            return []
        }
    }
    
    func fetchActiveCourses() async {
        guard let (data, _) = try? await CanvasService.shared.fetch(.getCourses(enrollmentState: "active")) else {
            print("Failed to fetch files.")
            return
        }
        
        if let retCourses = try? JSONDecoder().decode([Course].self, from: data) {
            self.courses = retCourses
        } else {
            print("Failed to decode file data.")
        }
    }
    
    func fetchAllClassesWith(userID: Int) async -> ([Course]) {
        await fetchActiveCourses()
        
        var commonCourses = [Course]()
        
        for course in courses {
            print("Is user in \(String(describing: course.name))?")
            
            // get enrollments in
            guard let courseID = course.id else { continue }
            let enrollments = await fetchPeopleWith(courseID: courseID)
            
            for enrollment in enrollments {
                if let user = enrollment.user {
                    if userID == user.id {
                        print("Yes")
                        commonCourses.append(course)
                        break
                    }
                }
            }
        }
        
        print("number of common course: \(commonCourses.count)")
        return commonCourses
    }
}
