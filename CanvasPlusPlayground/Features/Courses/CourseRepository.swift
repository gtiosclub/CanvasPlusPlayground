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
    func getCourses(withIds ids: [PersistentIdentifier]) -> [Course]

    @MainActor
    func deleteCourses(_ persistentIds: [PersistentIdentifier]) async throws

    @MainActor
    func deleteCourses(
        enrollmentType: EnrollmentType?,
        enrollmentState: GetCoursesRequest.StateFilter?,
        excludeBlueprintCourses: Bool,
        state: [CourseState],
        pageConfiguration: PageConfiguration
    ) async

    @MainActor
    func syncCourses(_ courses: [CourseAPI], pageConfig: PageConfiguration) -> [Course]
}

extension CourseRepository {
    @MainActor
    var mainContext: ModelContext {
        .shared
    }
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

        return (try? mainContext.fetch(descriptor)) ?? []
    }

    @MainActor
    func getCourses(withIds ids: [PersistentIdentifier]) -> [Course] {
        return ids.compactMap {
            mainContext.registeredModel(for: $0)
        }
    }

    @MainActor
    func deleteCourses(_ persistentIds: [PersistentIdentifier]) async throws {
        try mainContext.transaction {
            try mainContext.delete(model: Course.self, where: #Predicate<Course> { persistentIds.contains($0.persistentModelID) })
        }
    }

    @MainActor
    func deleteCourses(
        enrollmentType: EnrollmentType?,
        enrollmentState: GetCoursesRequest.StateFilter?,
        excludeBlueprintCourses: Bool,
        state: [CourseState],
        pageConfiguration: PageConfiguration
    ) async {
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
            try mainContext.transaction {
                try mainContext.delete(model: Course.self, where: predicate)
            }
        } catch {
            LoggerService.main.error("[CourseRepositoryImpl] Failure in deleting courses: \(error)")
        }
    }

    @MainActor
    func syncCourses(_ courses: [CourseAPI], pageConfig: PageConfiguration) -> [Course] {
        do {
            var coursesRes = [Course]()
            // All or nothing block to maintain consistency in `order` property
            try mainContext.transaction {
                let courseModels = courses.map { Course($0) }

                coursesRes = courseModels.enumerated()
                    .map { (i, course) in
                        switch pageConfig {
                        case .page:
                            course.order = pageConfig.offset + i
                        case .all:
                            course.order = i
                        }

                        if let dbCourse = mainContext.existingModel(forId: course.id) as Course? {
                            dbCourse.merge(with: course)
                            return dbCourse
                        }

                        mainContext.insert(course)

                        return course
                    }
            }

            return coursesRes
        } catch {
            LoggerService.main.error("Failed to persist courses: \(error)")

            return []
        }
    }
}
