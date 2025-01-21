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

    var users = [User]()

    init(courseID: String?) {
        self.courseID = courseID
    }

    func fetchPeople(at page: Int, searchTerm: String? = nil, roles: [EnrollmentType]) async {
        guard let courseID else { return }

        // Implies new search query
        if page == 1 {
            users = []
        }

        let request = CanvasRequest.getUsers(
            courseId: courseID,
            include: [.enrollments],
            searchTerm: searchTerm,
            enrollmentType: roles
        )

        var users: [User] = []
        do {
            users = try await CanvasService.shared.syncWithAPI(
                request,
                loadingMethod: .page(order: page)
            )
        } catch {
            print("Error fetching users: \(error)")

            do {
                users = (
                    try await CanvasService.shared.load(request, loadingMethod: .page(order: 1)) ?? []
                )
            } catch {
                print("Error loading users from storage: \(error)")
            }

        }

        addUsers(users)
    }

    private func addUsers(_ users: [User]) {
        DispatchQueue.main.async {
            self.users.append(contentsOf: users)
        }
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
