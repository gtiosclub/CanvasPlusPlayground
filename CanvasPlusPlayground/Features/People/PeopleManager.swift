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

            await addNewUsers(users)
        } catch {
            // don't make offline query if request was cancelled
            if let error = error as? URLError, error.code == .cancelled {
                return
            }
            LoggerService.main.error("Error fetching users: \(error)")

            if queryMode == .live && page == 1 {
                await setQueryMode(.offline)
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

                    let courseIsShared = enrollments.compactMap(\.user?.id.asString).contains(userID)
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
                    guard let _: [Enrollment] = try? await CanvasService.shared.loadAndSync(
                        request,
                        onCacheReceive: { cached in
                            guard let cached else { return }

                            processEnrollments(cached)
                        }, loadingMethod: .all(onNewPage: processEnrollments)
                    ) else {
                        LoggerService.main.error("Couldn't fetch enrollment count for course \(course.name ?? "n/a")")
                        return
                    }
                }
            }
        }
    }
}
