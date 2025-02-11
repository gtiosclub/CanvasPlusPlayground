//
//  GetCoursesRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/20/24.
//

import Foundation

struct GetCoursesRequest: CacheableArrayAPIRequest {
    typealias Subject = CourseAPI

    var path: String { "courses" }
    var queryParameters: [QueryParameter] {
        [
            ("enrollment_type", enrollmentType),
            ("enrollment_role", enrollmentRole),
            ("enrollment_role_id", enrollmentRoleId),
            ("enrollment_state", enrollmentState),
            ("exclude_blueprint_courses", excludeBlueprintCourses),
            ("state", state),
            ("per_page", perPage)
        ]
        + include.map { ("include[]", $0.rawValue) }
        + state.map { ("state[]", $0.rawValue) }
    }

    // MARK: Query Params
    let enrollmentType: String?
    let enrollmentRole: String?
    let enrollmentRoleId: Int?
    let enrollmentState: String?
    let excludeBlueprintCourses: Bool?
    let include: [Include]
    let state: [State]
    let perPage: Int

    init(
        enrollmentType: String? = nil,
        enrollmentRole: String? = nil,
        enrollmentRoleId: Int? = nil,
        enrollmentState: String? = nil,
        excludeBlueprintCourses: Bool? = nil,
        include: [Include] = [],
        state: [State] = [],
        perPage: Int = 50
    ) {
        self.enrollmentType = enrollmentType
        self.enrollmentRole = enrollmentRole
        self.enrollmentRoleId = enrollmentRoleId
        self.enrollmentState = enrollmentState
        self.excludeBlueprintCourses = excludeBlueprintCourses
        self.include = include
        self.state = state
        self.perPage = perPage
    }

    // MARK: request Id
    var requestId: String { "courses_\(StorageKeys.accessTokenValue)" }
    var requestIdKey: ParentKeyPath<Course, String> { .createWritable(\.parentId) }
    var idPredicate: Predicate<Course> {
        #Predicate<Course> { course in
            course.parentId == requestId
        }
    }
    var customPredicate: Predicate<Course> {

        let enrollmentTypePred: Predicate<Course>
        if let enrollmentType {
            enrollmentTypePred = #Predicate<Course> { course in
                course.enrollmentTypesRaw.localizedStandardContains(enrollmentType)
            }
        } else { enrollmentTypePred = Predicate<Course>.true }

        let enrollmentRolePred: Predicate<Course>
        if let enrollmentRole {
            enrollmentRolePred = #Predicate<Course> { course in
                course.enrollmentRolesRaw.localizedStandardContains(enrollmentRole)
            }
        } else { enrollmentRolePred = .true }

        let enrollmentRoleIdPred: Predicate<Course>
        if let enrollmentRoleId = enrollmentRoleId?.asString {
            enrollmentRoleIdPred = #Predicate<Course> { course in
                course.enrollmentRoleIds.localizedStandardContains(enrollmentRoleId)
            }
        } else { enrollmentRoleIdPred = .true }

        let enrollmentStatePred: Predicate<Course>
        if let enrollmentState {
            enrollmentStatePred = #Predicate<Course> { course in
                course.enrollmentStatesRaw.localizedStandardContains(enrollmentState)
            }
        } else { enrollmentStatePred = .true }

//        let excludeBluePrintPred = excludeBlueprintCourses == nil ? .true : #Predicate<Course> { course in
//            !(course.blueprint == true)
//        }

//        let statePred = state.isEmpty ? .true : #Predicate<Course> { course in
//            state.contains(course.workflowState)
//        }

        return #Predicate<Course> { course in
            enrollmentTypePred.evaluate(course)
            && enrollmentRolePred.evaluate(course)
            && enrollmentRoleIdPred.evaluate(course)
            && enrollmentStatePred.evaluate(course)
//            && excludeBluePrintPred.evaluate(course)
//            && statePred.evaluate(course)
        }
    }
}

extension GetCoursesRequest {
    enum Include: String {
        case needsGradingCount = "needs_grading_count",
             syllabusBody = "syllabus_body",
             publicDescription = "public_description",
             totalScores = "total_scores",
             currentGradingPeriodScores = "current_grading_period_scores",
             gradingPeriods = "grading_periods",
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
             courseImage = "course_image",
             bannerImage = "banner_image",
             concluded,
             postManually = "post_manually"
    }

    enum State: String {
        case unpublished, available, completed, deleted
    }
}
