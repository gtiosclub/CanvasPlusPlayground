//
//  CourseServicing.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 4/3/25.
//


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
