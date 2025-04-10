//
//  PeopleManager.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 9/22/24.
//

import SwiftData
import SwiftUI

@Observable
class PeopleManager: SearchResultListDataSource {
    // MARK: SearchResultListDatasource

    let label: String = "People"

    var loadingState: LoadingState = .nextPageReady
    var queryMode: PageMode = .live

    func fetchNextPage() async {
        await setLoadingState(.loading)
        do {
            try await fetchPeople()
        } catch {
            await setLoadingState(.error())
        }
    }

    // MARK: People
    private let courseID: String?

    var page: Int = 1 // 1-indexed
    var searchText: String = ""
    var selectedRoles: [EnrollmentType] = []

    var users = Set<User>()
    var displayedUsers: [User] {
        users.filter { user in
            let matchesSearchText = searchText.isEmpty || user.name.localizedCaseInsensitiveContains(searchText)

            let matchesSelectedTokens = selectedRoles.allSatisfy { role in
                user.enrollmentRoles.contains(role)
            }

            return matchesSearchText && matchesSelectedTokens
        }
        .sorted { $0.sortableName < $1.sortableName }
    }

    init(
        courseID: String?
    ) {
        self.courseID = courseID
    }

    @MainActor
    func fetchPeople() async throws {
        guard let courseID else { return }

        let request = CanvasRequest.getUsers(
            courseId: courseID,
            include: [.enrollments, .avatarUrl, .bio, .pronouns],
            searchTerm: searchText.count >= 2 ? searchText : "",
            enrollmentType: selectedRoles,
            perPage: 60
        )

        var users: [User] = []
        do {
            switch queryMode {
            case .live:
                users = try await CanvasService.shared.syncWithAPI(
                    request,
                    loadingMethod: .page(order: page)
                )
            case .offline:
                users = (
                    try await CanvasService.shared
                        .load(
                            request, loadingMethod: .page(order: page)
                        ) ?? []
                )
            }

            addNewUsers(users)
        } catch {
            // don't make offline query if request was cancelled
            if let error = error as? URLError, error.code == .cancelled {
                return
            }
            LoggerService.main.error("Error fetching users: \(error)")

            if queryMode == .live && page == 1 {
                setQueryMode(.offline)
                try await fetchPeople()
            } else {
                throw error
            }
        }
    }

    @MainActor
    private func addNewUsers(_ newUsers: [User]) {
        // Implies new search query
        if page == 1 {
            LoggerService.main.debug("Users: \(self.users.map(\.name))")
            self.users = []
        }

        self.users.formUnion(newUsers)

        // no users means no more pages
        if newUsers.isEmpty {
            setLoadingState(.idle)
        } else {
            setLoadingState(.nextPageReady)
            page += 1
        }
    }
}

// MARK: Shared Classes Feature
extension PeopleManager {
    static func fetchAllClassesWith(
        userID: String,
        activeCourses courses: [Course],
        receivedNewCourse: @MainActor @escaping (Course) -> Void = { _ in }
    ) async {
        await withTaskGroup(of: Void.self) { group in
            let maxConcurrentTasks = 10 // too many concurrent requests causes immediate failure
            for (i, course) in courses.enumerated() {
                if i >= maxConcurrentTasks {
                    await group.next()
                }

                group.addTask {
                    if await userIsInCourse(userId: userID, courseId: course.id) {
                        await receivedNewCourse(course)
                    } else {
                        LoggerService.main.error("User \(userID) not found in course \(course.name ?? "N/A")")
                    }
                }

            }
        }
    }

    @MainActor
    private static func userIsInCourse(userId: String, courseId: String) async -> Bool {
        let request = CanvasRequest.getEnrollments(courseId: courseId, userId: userId)

        // If user shared course is already known, move on
        if let numEnrollments = try? await CanvasService.shared.loadCount(request), numEnrollments > 0  {
            return true
        }

        if let enrollments = try? await CanvasService.shared.syncWithAPI(request), enrollments.count > 0 {
            return true
        } else {
            return false
        }
    }
}
