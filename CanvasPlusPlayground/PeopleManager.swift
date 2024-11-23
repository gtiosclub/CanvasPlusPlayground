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
    var users: [User] {
        enrollments.compactMap(\.user)
    }
    var courses = [Course]()

    init(courseID: String?) {
        self.courseID = courseID
        self.enrollments = []
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
                
                addEnrollments(cached)
            },
            onNewBatch: { enrollmentsBatch in
                addEnrollments(enrollmentsBatch)
            }
        )
        
        guard let enrollments else {
            print("Enrollments is nil, fetch failed.")
            return
        }
        
        self.enrollments = enrollments
    }
    
    private func addEnrollments(_ enrollments: [Enrollment]) {
        self.enrollments = Set(self.enrollments + enrollments).sorted {
            guard let name1 = $0.user?.name, let name2 = $1.user?.name else { return false }
            return (name1) < (name2)
        }
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
        
        await withTaskGroup(of: Void.self, body: { group in
            for course in courses {
                group.addTask { [weak self] in
                    print("Is user in \(String(describing: course.name))?")
                    
                    // get enrollments in
                    let courseID = course.id
                    let _: [Enrollment]? = try? await CanvasService.shared.syncWithAPI(.getPeople(courseId: courseID))
                    
                    let courseIsShared = self?.enrollments.compactMap(\.user?.id).contains([userID])
                    if let courseIsShared, courseIsShared {
                        print("User \(userID) is also in course \(course.name ?? "n/a").")
                        commonCourses.append(course)
                    }
                }
            }
        })
        
        print("number of common course: \(commonCourses.count)")
        return commonCourses
    }
}
