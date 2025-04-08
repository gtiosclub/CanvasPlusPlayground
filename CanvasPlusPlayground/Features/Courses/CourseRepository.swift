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
    func getCourses(withIds ids: [String]) -> [Course]

    func deleteCourses(_ persistentIds: [PersistentIdentifier]) async throws

    func deleteCourses(
        enrollmentType: EnrollmentType?,
        enrollmentState: GetCoursesRequest.StateFilter?,
        excludeBlueprintCourses: Bool,
        state: [CourseState],
        pageConfiguration: PageConfiguration
    ) async

    func syncCourses(_ courses: [CourseAPI], pageConfig: PageConfiguration) async -> [String]
}

extension CourseRepository {
    var writeHandler: StorageWriteHandler {
        StorageWriteHandler(modelContainer: .shared)
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
        let mainContext = ModelContext.shared

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
    func getCourses(withIds ids: [String]) -> [Course] {
        let mainContext = ModelContext.shared

        return ids.compactMap {
            mainContext.existingModel(forId: $0)
        }
    }

    func deleteCourses(_ persistentIds: [PersistentIdentifier]) async throws {
        try await writeHandler.transaction { context in
            try context.delete(model: Course.self, where: #Predicate<Course> { persistentIds.contains($0.persistentModelID) })
        }
    }

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
            try await writeHandler.transaction { context in
                try context.delete(model: Course.self, where: predicate)
            }
        } catch {
            LoggerService.main.error("[CourseRepositoryImpl] Failure in deleting courses: \(error)")
        }
    }

    func syncCourses(_ courses: [CourseAPI], pageConfig: PageConfiguration) async -> [String] {
        let writeHandler = writeHandler

        do {
            // All or nothing block to maintain consistency in `order` property
            let courseIds: [String] = try await writeHandler.transaction { context in
                let courseModels = courses.map { Course($0) }

                return courseModels.enumerated()
                    .map { (i, course) in
                        switch pageConfig {
                        case .page:
                            course.order = pageConfig.offset + i
                        case .all:
                            course.order = i
                        }

                        if let dbCourse = context.existingModel(forId: course.id) as Course? {
                            dbCourse.merge(with: course)
                            return dbCourse
                        }

                        context.insert(course)

                        return course
                    }
            }
            .map { $0.id }

            return courseIds
        } catch {
            LoggerService.main.error("Failed to persist courses: \(error)")

            return []
        }
    }
}
