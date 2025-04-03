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
            ("enrollment_type", enrollmentType?.rawValue),
            ("enrollment_state", enrollmentState),
            ("exclude_blueprint_courses", excludeBlueprintCourses),
            ("state", state),
            ("per_page", perPage)
        ]
        + include.map { ("include[]", $0.rawValue) }
        + state.map { ("state[]", $0.rawValue) }
    }

    // MARK: Query Params
    let enrollmentType: CourseEnrollmentFilter?
    let enrollmentState: StateFilter?
    let excludeBlueprintCourses: Bool
    let include: [Include]
    let state: [CourseState]
    let perPage: Int

    init(
        enrollmentType: EnrollmentType? = nil,
        enrollmentState: StateFilter? = nil,
        excludeBlueprintCourses: Bool = false,
        include: [Include] = [],
        state: [CourseState] = [],
        perPage: Int = 50
    ) {
        self.enrollmentType = CourseEnrollmentFilter(type: enrollmentType)
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
//        let enrollmentTypePred: Predicate<Course>
//        if let enrollmentType {
//            enrollmentTypePred = #Predicate<Course> { course in
//                course.enrollmentTypesRaw.localizedStandardContains(enrollmentType)
//            }
//        } else { enrollmentTypePred = Predicate<Course>.true }
//
//        let enrollmentRolePred: Predicate<Course>
//        if let enrollmentRole {
//            enrollmentRolePred = #Predicate<Course> { course in
//                course.enrollmentRolesRaw.localizedStandardContains(enrollmentRole)
//            }
//        } else { enrollmentRolePred = .true }
//
//        let enrollmentRoleIdPred: Predicate<Course>
//        if let enrollmentRoleId = enrollmentRoleId?.asString {
//            enrollmentRoleIdPred = #Predicate<Course> { course in
//                course.enrollmentRoleIds.localizedStandardContains(enrollmentRoleId)
//            }
//        } else { enrollmentRoleIdPred = .true }
//
//        let enrollmentStatePred: Predicate<Course>
//        if let enrollmentState {
//            enrollmentStatePred = #Predicate<Course> { course in
//                course.enrollmentStatesRaw.localizedStandardContains(enrollmentState)
//            }
//        } else { enrollmentStatePred = .true }

        // swiftlint:disable commented_code
//        let excludeBluePrintPred = excludeBlueprintCourses == nil ? .true : #Predicate<Course> { course in
//            !(course.blueprint == true)
//        }

//        let statePred = state.isEmpty ? .true : #Predicate<Course> { course in
//            state.contains(course.workflowState)
//        }

        return #Predicate<Course> { course in
            true
//            enrollmentTypePred.evaluate(course)
//            && enrollmentRolePred.evaluate(course)
//            && enrollmentRoleIdPred.evaluate(course)
//            && enrollmentStatePred.evaluate(course)
//            && excludeBluePrintPred.evaluate(course)
//            && statePred.evaluate(course)
        }
        // swiftlint:enable commented_code
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

    enum StateFilter: String {
        case active, invitedOrPending = "invited_or_pending", completed
    }

    enum CourseEnrollmentFilter: String {
        case teacher, student, ta, observer, designer

        init?(type: EnrollmentType?) {
            switch type {
            case .teacher:
                self = .teacher
            case .student:
                self = .student
            case .taEnrollment:
                self = .ta
            case .observer:
                self = .observer
            case .designer:
                self = .designer
            default:
                return nil
            }
        }
    }
}
