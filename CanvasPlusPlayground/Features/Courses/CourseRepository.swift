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
  
    func deleteCourses(withIds ids: [String]) async throws

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
    var writeHandler: StorageHandler {
        StorageHandler(modelContainer: .shared)
    }

    @MainActor
    var mainContext: ModelContext {
        .shared
    }
}

class CourseRepositoryImpl: CourseRepository {

    private func predicate(
        enrollmentType: EnrollmentType?,
        enrollmentState: GetCoursesRequest.StateFilter?,
        excludeBlueprintCourses: Bool,
        state: [CourseState]
    ) -> Predicate<Course> {
        let enrollmentTypeRaw = enrollmentType?.rawValue ?? ""
        let enrollmentStateRaw = enrollmentState?.rawValue ?? ""
        let state = state as [CourseState?]
        let predicate = #Predicate<Course> {
            (enrollmentTypeRaw == "" || $0.enrollmentTypesRaw.localizedStandardContains(enrollmentTypeRaw)) &&
            (enrollmentStateRaw == "" || $0.enrollmentStatesRaw.localizedStandardContains(enrollmentStateRaw)) &&
            (!excludeBlueprintCourses || $0.blueprint != true) &&
            (state.isEmpty || state.contains($0.workflowState))
        }

        return predicate
    }

    @MainActor
    func getCourses(
        enrollmentType: EnrollmentType?,
        enrollmentState: GetCoursesRequest.StateFilter?,
        excludeBlueprintCourses: Bool,
        state: [CourseState],
        pageConfiguration: PageConfiguration
    ) -> [Course] {
        let mainContext = ModelContext.shared

        var descriptor = FetchDescriptor(
            predicate: predicate(enrollmentType: enrollmentType, enrollmentState: enrollmentState, excludeBlueprintCourses: excludeBlueprintCourses, state: state),
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

    func deleteCourses(withIds ids: [String]) async throws {
        try await writeHandler.transaction { context in
            try context.delete(model: Course.self, where: #Predicate<Course> { ids.contains($0.id) })
        }
    }

    func deleteCourses(
        enrollmentType: EnrollmentType?,
        enrollmentState: GetCoursesRequest.StateFilter?,
        excludeBlueprintCourses: Bool,
        state: [CourseState],
        pageConfiguration: PageConfiguration
    ) async {
        do {
            try await writeHandler.transaction { context in
                try context.delete(model: Course.self, where: predicate(enrollmentType: enrollmentType, enrollmentState: enrollmentState, excludeBlueprintCourses: excludeBlueprintCourses, state: state))
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
                return (courses.enumerated().map { (i, courseApi) in
                    let course = Course(courseApi)

                    let newTabs: [CanvasTab] = courseApi.tabs?.compactMap { tabApi in
                        if let existingTab = context.existingModel(forId: tabApi.id) as CanvasTab? {
                            existingTab.merge(with: tabApi)
                            if course.tabs.contains(existingTab) { return nil }
                            else { return existingTab }
                        } else {
                            return CanvasTab(from: tabApi, tabOrigin: .course(id: course.id))
                        }
                    } ?? []


                    switch pageConfig {
                    case .page:
                        course.order = pageConfig.offset + i
                    case .all:
                        course.order = i
                    }

                    if let dbCourse = context.existingModel(forId: course.id) as Course? {
                        dbCourse.merge(with: course)
                        dbCourse.tabs.append(contentsOf: newTabs)
                        return dbCourse
                    }

                    context.insert(course)
                    course.tabs.append(contentsOf: newTabs)

                    return course
                } as [Course])
                .map { $0.id }
            }

            return courseIds
        } catch {
            LoggerService.main.error("Failed to persist courses: \(error)")

            return []
        }
    }
}
