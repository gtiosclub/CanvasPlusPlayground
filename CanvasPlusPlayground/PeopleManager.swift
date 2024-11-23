//
//  PeopleManager.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 9/22/24.
//

import SwiftUI

@Observable
class PeopleManager {
    private let courseID: String?
    var enrollments = [Enrollment]()
    var users = [User] ()
    var courses = [Course]()

    init(courseID: String?) {
        self.courseID = courseID
        self.enrollments = []
        self.users = []
    }
    
    func fetchPeople() async {
        guard let courseID else { return }

        let enrollments: [Enrollment]? = try? await CanvasService.shared.loadAndSync(
            .getPeople(courseId: courseID),
            descriptor: .init(sortBy: [
                SortDescriptor(\.user?.name, order: .forward)
            ]),
            onCacheReceive: { (cached: [Enrollment]?) in
                guard let cached else { return }

                let users = cached.compactMap { $0.user }
                        .filter { user in !self.users.contains(where: { $0.id == user.id }) }

                self.users = users
            }
        )
        
        guard let enrollments else {
            print("Enrollments is nil, fetch failed.")
            return
        }
        
        self.enrollments = enrollments
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
            let courseID = course.id
            
            let _ = try? await CanvasService.shared.fetchBatch(.getPeople(courseId: courseID)) { dataResponseArr in
                do {
                    let enrollments = try CanvasService.shared.decodeData(arg: dataResponseArr) as [Enrollment]
                    
                    // this is a completion that is executed once the function has finished
                    for enrollment in enrollments {
                        if let user = enrollment.user {
                            self.users.append(user)
                        }
                    }
                } catch {
                    print(error)
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
