//
//  CourseServicing.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 4/3/25.
//


protocol CourseServicing {
    var courseRepository: CourseRepository { get set }

    func getCourses(
        enrollmentType: EnrollmentType?,
        enrollmentState: GetCoursesRequest.StateFilter?,
        excludeBlueprintCourses: Bool,
        state: [CourseState],
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
        enrollmentType: EnrollmentType?,
        enrollmentState: GetCoursesRequest.StateFilter?,
        excludeBlueprintCourses: Bool,
        state: [CourseState],
        pageConfiguration: PageConfiguration
    ) async throws -> [Course] {
        let coursesRequest = GetCoursesRequest(
            enrollmentType: enrollmentType,
            enrollmentState: enrollmentState,
            excludeBlueprintCourses: excludeBlueprintCourses,
            include: GetCoursesRequest.Include.allCases,
            state: state,
            perPage: pageConfiguration.perPage
        )

        do {
            let courses = try await CanvasService.shared.fetch(
                coursesRequest,
                loadingMethod: { // TODO: pageConfiguration should directly go into `fetch`
                    // ideally we dont use `.all`
                    switch pageConfiguration {
                    case let .page(pageNum, _):
                        return .page(order: pageNum)
                    case .all:
                        return .all(onNewPage: { _ in })
                    }
                }()
            )

            // TODO: delete old courses here correctly
            await self.courseRepository.deleteCourses(
                enrollmentType: enrollmentType,
                enrollmentState: enrollmentState,
                excludeBlueprintCourses: excludeBlueprintCourses,
                state: state,
                pageConfiguration: pageConfiguration
            )

            return await self.courseRepository.syncCourses(courses, pageConfig: pageConfiguration)
        } catch {
            return await courseRepository.getCourses(
                enrollmentType: enrollmentType,
                enrollmentState: enrollmentState,
                excludeBlueprintCourses: excludeBlueprintCourses,
                state: state,
                pageConfiguration: pageConfiguration
            )
        }
    }
}
