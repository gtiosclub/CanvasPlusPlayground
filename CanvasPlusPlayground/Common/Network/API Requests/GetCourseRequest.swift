//
//  GetCourseRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/20/24.
//
import Foundation

struct GetCourseRequest: CacheableAPIRequest {
    typealias Subject = CourseAPI

    let courseId: String

    var path: String { "courses/\(courseId)" }
    var queryParameters: [QueryParameter] {
        [
            ("teacher_limit", teacherLimit)
        ]
        + include.map { ("include[]", $0.rawValue) }
    }

    let include: [Include]
    let teacherLimit: Int?

    init(courseId: String, include: [Include] = [], teacherLimit: Int? = nil) {
        self.courseId = courseId
        self.include = include
        self.teacherLimit = teacherLimit
    }

    var requestId: String { courseId }
    var requestIdKey: ParentKeyPath<Course, String> { .createReadable(\.id) }
    var idPredicate: Predicate<Course> {
        #Predicate<Course> { course in
            course.id == courseId
        }
    }
    var customPredicate: Predicate<Course> {
        .true
    }
}

extension GetCourseRequest {
    enum Include: String {
        case needsGradingCount = "needs_grading_count",
             syllabusBody = "syllabus_body",
             publicDescription = "public_description",
             totalScores = "total_scores",
             currentGradingPeriodScores = "current_grading_period_scores",
             term,
             account,
             courseProgress = "course_progress",
             sections,
             storageQuotaUsedMb = "storage_quota_used_mb",
             totalStudents = "total_students",
             passbackStatus = "passback_status",
             favorites,
             teachers,
             observedUsers = "observed_users",
             allCourses = "all_courses",
             permissions,
             courseImage = "course_image",
             bannerImage = "banner_image",
             concluded,
             ltiContextId = "lti_context_id",
             postManually = "post_manually"
    }
}
