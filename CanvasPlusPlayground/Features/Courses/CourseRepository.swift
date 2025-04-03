//
//  CourseRepository.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 4/1/25.
//

import Foundation
import SwiftData

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
