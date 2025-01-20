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

    private var enrollments = [Enrollment]()

    var users = [User]()
//    {
//        Set(
//            enrollments
//                .compactMap {
//                    guard var user = $0.user else { return nil }
//                    user.role = $0.displayRole
//                    return user
//                }1
//        ).sorted {
//            ($0.name) < ($1.name)
//        }
//    }

    init(courseID: String?) {
        self.courseID = courseID
    }

    func fetchPeople() async {
        guard let courseID else { return }

        let users: [User]? = try? await CanvasService.shared.loadAndSync(
            CanvasRequest.getUsers(courseId: courseID)
        )
        let enrollments: [Enrollment]? = try? await CanvasService.shared.loadAndSync(
            CanvasRequest.getEnrollments(courseId: courseID),
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

        setEnrollments(enrollments)
    }

    private func addEnrollments(_ enrollments: [Enrollment]) {
        DispatchQueue.global().sync {
            let enrollments = Set(self.enrollments + enrollments).sorted {
                guard let name1 = $0.user?.name, let name2 = $1.user?.name else { return false }
                return (name1) < (name2)
            }

            setEnrollments(enrollments)
        }
    }

    private func setEnrollments(_ enrollments: [Enrollment]) {
        self.enrollments = enrollments
    }

    func fetchAllClassesWith(
        userID: Int,
        activeCourses courses: [Course],
        receivedNewCourse: @escaping (Course) -> Void = { _ in }
    ) async {
        let commonCoursesQueue = DispatchQueue(label: "com.CanvasPlus.commonCoursesQueue")

        await withTaskGroup(of: Void.self) { group in
            for course in courses {
                var didAlreadyAddCourse = false
                let courseID = course.id
                let request = CanvasRequest.getEnrollments(courseId: courseID, userId: userID)

                func processEnrollments(_ enrollments: [Enrollment]) {
                    guard !didAlreadyAddCourse else { return }

                    let courseIsShared = enrollments.compactMap(\.user?.id).contains([userID])
                    if courseIsShared {
                        // Found a Common Course

                        didAlreadyAddCourse = true
                        commonCoursesQueue.sync {
                            receivedNewCourse(course)
                        }
                    }
                }

                group.addTask {
                    // Get the enrollments of course
                    // swiftlint:disable:next unused_optional_binding
                    guard let _: [Enrollment] = try? await CanvasService.shared.loadAndSync(request, onCacheReceive: { cached in
                        guard let cached else { return }

                        processEnrollments(cached)
                    }, onNewBatch: { batchedResults in
                        processEnrollments(batchedResults)
                    }) else {
                        // TODO: indicate network error here
                        print("Couldn't fetch enrollment count for course \(course.name ?? "n/a")")
                        return
                    }
                }
            }
        }
    }
}
