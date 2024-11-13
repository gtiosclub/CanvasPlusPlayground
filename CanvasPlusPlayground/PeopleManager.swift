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

    func fetchPeopleWith(courseID: Int) async {
        
        await CanvasService.shared.fetchBatch(.getPeople(courseId: courseID), oneNewBatch: { (data, response) in
            do {
                let enrollments = try JSONDecoder().decode([Enrollment].self, from: data)
                for enrollment in enrollments {
                    if let user = enrollment.user {
                        self.users.append(user)
                    }
                }
            } catch {
                print(error)
            }
        })
    }
    
    func fetchActiveCourses() async {
        guard let (data, _) = try? await CanvasService.shared.fetchResponse(.getCourses(enrollmentState: "active")) else {
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
            
            await CanvasService.shared.fetchBatch(.getPeople(courseId: courseID)) { dataResponseArr in
                // this is a completion that is executed once the function has finished
                for (data, response) in dataResponseArr {
                    do {
                        let enrollments = try JSONDecoder().decode([Enrollment].self, from: data)
                        for enrollment in enrollments {
                            if let user = enrollment.user {
                                self.users.append(user)
                            }
                        }
                    } catch {
                        print(error)
                    }
                }
                
            }
            
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
