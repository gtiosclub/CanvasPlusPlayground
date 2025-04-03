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
                (enrollmentTypeRaw == "" || $0.enrollmentTypesRaw.localizedStandardContains(enrollmentTypeRaw)) &&
                (enrollmentStateRaw == "" || $0.enrollmentStatesRaw.localizedStandardContains(enrollmentStateRaw)) &&
                (!excludeBlueprintCourses || $0.blueprint == true) &&
                (state.isEmpty || state.contains($0.workflowState))
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
        let state = state as [CourseState?]
        let predicate = #Predicate<Course> {
            (enrollmentTypeRaw == "" || $0.enrollmentTypesRaw.localizedStandardContains(enrollmentTypeRaw)) &&
            (enrollmentStateRaw == "" || $0.enrollmentStatesRaw.localizedStandardContains(enrollmentStateRaw)) &&
            (!excludeBlueprintCourses || $0.blueprint == true) &&
            (state.isEmpty || state.contains($0.workflowState))
        }

        do {
            try ModelContext.shared.delete(model: Course.self, where: predicate)
            try ModelContext.shared.save()
        } catch {
            LoggerService.main.error("[CourseRepositoryImpl] Failure in deleting courses: \(error)")
        }
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
