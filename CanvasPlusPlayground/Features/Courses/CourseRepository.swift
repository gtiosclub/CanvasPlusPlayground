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
        enrollmentType: EnrollmentType?,
        enrollmentState: GetCoursesRequest.StateFilter?,
        excludeBlueprintCourses: Bool,
        state: [CourseState],
        pageConfiguration: PageConfiguration
    ) -> [Course]

    @MainActor
    func deleteCourses(_ courses: [Course])

    @MainActor
    func deleteCourses(
        enrollmentType: EnrollmentType?,
        enrollmentState: GetCoursesRequest.StateFilter?,
        excludeBlueprintCourses: Bool,
        state: [CourseState],
        pageConfiguration: PageConfiguration
    )

    @MainActor
    func syncCourses(_ courses: [CourseAPI], pageConfig: PageConfiguration) -> [Course]
}

class CourseRepositoryImpl: CourseRepository {
    
    @MainActor
    func getCourses(
        enrollmentType: EnrollmentType?,
        enrollmentState: GetCoursesRequest.StateFilter?,
        excludeBlueprintCourses: Bool,
        state: [CourseState],
        pageConfiguration: PageConfiguration
    ) -> [Course] {
        let context = ModelContext.shared

        let enrollmentTypeRaw = enrollmentType?.rawValue ?? ""
        let enrollmentStateRaw = enrollmentState?.rawValue ?? ""
        let state = state as [CourseState?]
        var descriptor = FetchDescriptor(
            predicate: #Predicate<Course> {
                $0.enrollmentTypesRaw.localizedStandardContains(enrollmentTypeRaw) &&
                $0.enrollmentStatesRaw.localizedStandardContains(enrollmentStateRaw) &&
                $0.blueprint == excludeBlueprintCourses &&
                state.contains($0.workflowState)
            },
            sortBy: [SortDescriptor(\.order)]
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
        enrollmentType: EnrollmentType?,
        enrollmentState: GetCoursesRequest.StateFilter?,
        excludeBlueprintCourses: Bool,
        state: [CourseState],
        pageConfiguration: PageConfiguration
    ) {
        // TODO: delete by filter
        let enrollmentTypeRaw = enrollmentType?.rawValue ?? ""
        let enrollmentStateRaw = enrollmentState?.rawValue ?? ""
        let states = state as [CourseState?]
        var predicate = #Predicate<Course> {
            $0.enrollmentTypesRaw.localizedStandardContains(enrollmentTypeRaw) &&
            $0.enrollmentStatesRaw.localizedStandardContains(enrollmentStateRaw) &&
            $0.blueprint == excludeBlueprintCourses
        }
        for state in states {
            predicate = #Predicate<Course> {
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
            case .page:
                course.order = pageConfig.offset + i
            case .all:
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
