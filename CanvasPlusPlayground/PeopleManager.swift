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

    var allCoursesCached = true

    init(courseID: String?) {
        self.courseID = courseID
        self.enrollments = []
        self.users = []
    }
    
    func fetchPeople() async {
        guard let courseID else { return }

        let _: [Enrollment]? = try? await CanvasService.shared.defaultAndFetch(
            .getPeople(courseId: courseID),
            onCacheReceive: { (cached: [Enrollment]?) in
                guard let cached else { return }

                let users = cached.compactMap { $0.user }
                        .filter { user in !self.users.contains(where: { $0.id == user.id }) }

                self.users.append(contentsOf: Set(users))
            },
            onNewBatch: { batch in
                let users = batch.compactMap { $0.user }
                                    .filter { user in !self.users.contains(where: { $0.id == user.id }) }

                self.users.append(contentsOf: Set(users))
            }
        )
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

            let enrollments: [Enrollment]? = try? await CanvasService.shared.fetchFromCache(
                .getPeople(courseId: course.id),
                condition: nil as LookupCondition<Enrollment, String>?
            )

            if enrollments == nil || enrollments!.isEmpty {
                allCoursesCached = false
            }

            for enrollment in enrollments ?? [] {
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
