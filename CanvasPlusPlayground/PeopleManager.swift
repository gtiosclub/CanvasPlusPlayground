//
//  PeopleManager.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 9/22/24.
//

import SwiftUI
import SwiftData

@Observable
class PeopleManager {
    private let courseID: String?

    var enrollments = [Enrollment]()
    var users: [User] {
        Set(enrollments.compactMap(\.user))
            .sorted {
                ($0.name ?? "") < ($1.name ?? "")
            }
    }

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
    
    private func fetchActiveCourses() async -> [Course] {
        guard let (data, _) = try? await CanvasService.shared.fetchResponse(.getCourses(enrollmentState: "active")) else {
            print("Failed to fetch courses.")
            return []
        }
        
        if let retCourses = try? JSONDecoder().decode([Course].self, from: data) {
            return retCourses
        } else {
            print("Failed to decode file data.")
            return []
        }
    }
    
    func fetchAllClassesWith(
        userID: Int,
        receivedNewCourse: @escaping (Course) -> Void = { _ in }
    ) async {
        let courses = await fetchActiveCourses()

        let commonCoursesQueue = DispatchQueue(label: "com.CanvasPlus.commonCoursesQueue")

        await withTaskGroup(of: Void.self) { group in
            for course in courses {                
                // get enrollments in
                let courseID = course.id
                let request = CanvasRequest.getPeople(courseId: courseID)
                
                func processEnrollments(_ enrollments: [Enrollment]) {
                    let courseIsShared = enrollments.compactMap(\.user?.id).contains([userID])
                    if courseIsShared {
                        print("User \(userID) is also in course \(course.name ?? "n/a").")
                        
                        commonCoursesQueue.sync {
                            receivedNewCourse(course)
                        }
                    }
                }
                
                group.addTask {
                    print("Is user in \(String(describing: course.name))?")
                    
                    // If request was already made, retrieve from cache
                    guard !CanvasService.shared.isRequestCompleted(request) else {
                        // Check that no loading error occurred
                        guard let enrollments = try? await CanvasService.shared.load(request) as [Enrollment]? else {
                            // TODO: indicate storage error here
                            print("Couldn't load enrollment count for course \(course.name ?? "n/a")")
                            return
                        }
                        
                        processEnrollments(enrollments)
                        
                        return
                    }
                    
                    guard let enrollments: [Enrollment] = try? await CanvasService.shared.loadAndSync(request, onCacheReceive: { cached in
                        guard let cached else { return }

                        processEnrollments(cached)
                    }) else {
                        // TODO: indicate network error here
                        print("Couldn't fetch enrollment count for course \(course.name ?? "n/a")")
                        return
                    }
                    
                    processEnrollments(enrollments)
                    
                    CanvasService.shared.markRequestAsCompleted(request)
                }
            }
        }
    }
}
