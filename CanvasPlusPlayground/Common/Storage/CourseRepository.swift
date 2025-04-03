//
//  CourseRepository.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 4/1/25.
//

import Foundation
import SwiftData

// PageConfiguration.swift
struct PageConfiguration {
    var perPage: Int
    var method: PaginationMethod // .page(pageNum:) OR .all

    enum PaginationMethod {
        /// 1-indexed. Get a specific page from offset (perPage*(pageNum-1))
        case page(pageNum: Int)
        /// Avoid using this for possibly large network/storage queries
        case all
    }

    var offset: Int {
        switch method {
        case .page(pageNum: let pageNum):
            return perPage * (pageNum - 1)
        case .all:
            return 0
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

        let courseStates = courseState.map { CourseWorkflowState(rawValue: $0) }
        var descriptor = FetchDescriptor(
            predicate: #Predicate<Course> {
                $0.enrollmentRoleIds.contains(enrollmentRole) &&
                courseStates.contains($0.workFlowState) &&
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
        let orderMin = {
            switch pageConfiguration.method {
            case .all:
                0
            case .page(pageNum: let pageNum):
                ((pageNum - 1) * pageConfiguration.perPage)
            }
        }()

        let orderMax = {
            switch pageConfiguration.method {
            case .all:
                Int.max
            case .page(pageNum: let pageNum):
                (pageNum * pageConfiguration.perPage)
            }
        }()

        // TODO: delete by filter
        let courseStates = courseState.map { CourseWorkflowState(rawValue: $0) }
        let predicate = #Predicate<Course> {
            $0.enrollmentRoleIds.contains(enrollmentRole) &&
            courseStates.contains($0.workFlowState) &&
            $0.enrollmentTypesRaw.contains(enrollmentType)
        }

        try? ModelContext.shared.delete(model: Course.self, where: predicate)
    }

    @MainActor
    func syncCourses(_ courses: [CourseAPI], pageConfig: PageConfiguration) -> [Course] {
        let courseModels = courses.map { Course($0) }

        let context = ModelContext.shared
        for (i, course) in courseModels.enumerated() {
            if case .page(let pageNum) = pageConfig.method {
                course.order = pageConfig.offset + i
            } else {
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

extension Course: @unchecked Sendable {}

class CourseService: CourseServicing {
    var courseRepository: any CourseRepository

    init(isTest: Bool) {
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
            include: [.favorites],
            state: courseState.compactMap { GetCoursesRequest.State(rawValue: $0) },
            perPage: pageConfiguration.perPage
        )

        do {
            let courses = try await CanvasService.shared.fetch(
                coursesRequest,
                loadingMethod: { // TODO: pageConfiguration should directly go into `fetch`
                    // ideally we dont use `.all`
                    if case .page(let pageNum) = pageConfiguration.method {
                        return .page(order: pageNum)
                    } else {
                        return .all(onNewPage: { _ in })
                    }
                }()
            )

            // TODO: delete old courses here

            return await courseRepository.syncCourses(courses, pageConfig: pageConfiguration)
        } catch {
            return await courseRepository.getCourses(
                enrollmentType: enrollmentType,
                enrollmentRole: enrollmentRole,
                courseState: courseState,
                pageConfiguration: pageConfiguration
            )
        }
    }
    

}
