//
//  CourseRepository.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 4/1/25.
//

import Foundation
import SwiftData

// TODO: PageConfiguration.swift
enum PageConfiguration {
    /// 1-indexed. Get a specific page from offset (perPage*(pageNum-1))
    case page(pageNum: Int, perPage: Int)
    /// Avoid using this for possibly large network/storage queries
    case all(perPage: Int)

    var perPage: Int {
        switch self {
        case let .page(_, perPage):
            return perPage
        case let .all(perPage):
            return perPage
        }
    }

    var offset: Int {
        switch self {
        case let .page(pageNum, perPage):
            return perPage * (pageNum - 1)
        case .all:
            return 0
        }
    }

    var orderMin: Int {
        offset
    }

    var orderMax: Int {
        switch self {
        case .all:
            Int.max
        case let .page(pageNum, perPage):
            (pageNum * self.perPage)
        }
    }
}

protocol CourseRepository {
    @MainActor
    func getCourses(
        enrollmentType: String,
        enrollmentRole: String,
        courseState: [String],
        pageConfiguration: PageConfiguration
    ) -> [Course]

    @MainActor
    func deleteCourses(_ courses: [Course])

    @MainActor
    func deleteCourses(
        enrollmentType: String,
        enrollmentRole: String,
        courseState: [String],
        pageConfiguration: PageConfiguration
    )

    @MainActor
    func syncCourses(_ courses: [CourseAPI], pageConfig: PageConfiguration) -> [Course]
}

class CourseRepositoryImpl: CourseRepository {
    @MainActor
    func getCourses(
        enrollmentType: String,
        enrollmentRole: String,
        courseState: [String],
        pageConfiguration: PageConfiguration
    ) -> [Course] {
        let context = ModelContext.shared

        let courseStates = courseState.map { CourseState(rawValue: $0) }
        var descriptor = FetchDescriptor(
            predicate: #Predicate<Course> {
                $0.enrollmentRoleIds.contains(enrollmentRole) &&
                courseStates.contains($0.workflowState) &&
                $0.enrollmentTypesRaw.contains(enrollmentType)
            },
            sortBy: [SortDescriptor(\.name)]
        )
        descriptor.fetchOffset = pageConfiguration.offset
        descriptor.fetchLimit = pageConfiguration.perPage

        return (try? context.fetch(descriptor)) ?? []
    }

    @MainActor
    func deleteCourses(_ courses: [Course]) {
        for course in courses {
            ModelContext.shared.delete(course)
        }
    }

    @MainActor
    func deleteCourses(
        enrollmentType: String,
        enrollmentRole: String,
        courseState: [String],
        pageConfiguration: PageConfiguration
    ) {
        // TODO: delete by filter
        let courseStates = courseState.map { CourseState(rawValue: $0) }
        var predicate = #Predicate<Course> {
            $0.enrollmentRoleIds.localizedStandardContains(enrollmentRole) &&
            $0.enrollmentTypesRaw.localizedStandardContains(enrollmentType) &&
            ($0.order) >= pageConfiguration.offset && ($0.order) < pageConfiguration.orderMax
        }
        for state in courseStates {
            predicate = #Predicate {
                predicate.evaluate($0) && $0.workflowState == state
            }
        }

        try? ModelContext.shared.delete(model: Course.self, where: predicate)
    }

    @MainActor
    func syncCourses(_ courses: [CourseAPI], pageConfig: PageConfiguration) -> [Course] {
        let courseModels = courses.map { Course($0) }

        let context = ModelContext.shared
        for (i, course) in courseModels.enumerated() {
            switch pageConfig {
            case let .page(pageNum, perPage):
                course.order = pageConfig.offset + i
            case .all(let perPage):
                course.order = i
            }
            context.insert(course)
        }

        do {
            try context.save()
            return courseModels
        } catch {
            LoggerService.main.error("Failed to persist courses: \(error)")
            return []
        }
    }
}

protocol CourseServicing {
    var courseRepository: CourseRepository { get set }

    func getCourses(
        enrollmentType: String,
        enrollmentRole: String,
        courseState: [String],
        pageConfiguration: PageConfiguration
    ) async throws -> [Course]

    // ...
}

class CourseService: CourseServicing {
    var courseRepository: any CourseRepository

    init(isTest: Bool = false) {
        self.courseRepository = CourseRepositoryImpl()
    }

    func getCourses(
        enrollmentType: String,
        enrollmentRole: String,
        courseState: [String],
        pageConfiguration: PageConfiguration
    ) async throws -> [Course] {
        let coursesRequest = GetCoursesRequest(
            enrollmentType: enrollmentType,
            enrollmentRole: enrollmentRole,
            enrollmentState: nil,
            excludeBlueprintCourses: false,
            include: [
                .favorites,
                .courseImage,
                .courseProgress,
                .concluded,
                .bannerImage,
                .needsGradingCount,
                .totalStudents,
                .totalScores,
                .sections,
                .observedUsers,
                .passbackStatus,
                .postManually,
                .term,
                .teachers,
                .syllabusBody
            ],
            state: courseState.compactMap { GetCoursesRequest.State(rawValue: $0) },
            perPage: pageConfiguration.perPage
        )

        let dbCourses = await courseRepository.getCourses(
            enrollmentType: enrollmentType,
            enrollmentRole: enrollmentRole,
            courseState: courseState,
            pageConfiguration: pageConfiguration
        )

        do {
            let courses = try await CanvasService.shared.fetch(
                coursesRequest,
                loadingMethod: { // TODO: pageConfiguration should directly go into `fetch`
                    // ideally we dont use `.all`
                    switch pageConfiguration {
                    case let .page(pageNum, perPage):
                        return .page(order: pageNum)
                    case .all(let perPage):
                        return .all(onNewPage: { _ in })
                    }
                }()
            )

            // TODO: delete old courses here correctly
            await self.courseRepository.deleteCourses(
                enrollmentType: enrollmentType,
                enrollmentRole: enrollmentRole,
                courseState: courseState,
                pageConfiguration: pageConfiguration
            )

            return await self.courseRepository.syncCourses(courses, pageConfig: pageConfiguration)
        } catch {
            return dbCourses
        }
    }
}
