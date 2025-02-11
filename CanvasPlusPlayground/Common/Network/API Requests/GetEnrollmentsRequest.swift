//
//  GetEnrollmentsRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/20/24.
//

import Foundation

struct GetEnrollmentsRequest: CacheableArrayAPIRequest {
    typealias Subject = EnrollmentAPI

    let courseId: String
    let courseEnrollmentTermId: Int?

    var path: String { "courses/\(courseId)/enrollments" }
    var queryParameters: [QueryParameter] {
        var params = [
            ("user_id", userId),
            ("grading_period_id", gradingPeriodId),
            ("enrollment_term_id", enrollmentTermId),
            ("per_page", perPage)
        ] as [(String, Any?)]
        params += type.map { ("type[]", $0) }
        params += role.map { ("role[]", $0) }
        params += state.map { ("state[]", $0) }
        params += include.map { ("include[]", $0) }
        params += sisAccountId.map { ("sis_account_id[]", $0) }
        params += sisCourseId.map { ("sis_course_id[]", $0) }
        params += sisSectionId.map { ("sis_section_id[]", $0) }
        params += sisUserId.map { ("sis_user_id[]", $0) }
        params += createdForSisId.map { ("created_for_sis_id[]", $0) }
        return params
    }

    // MARK: Query Params
    let type: [EnrollmentType]
    let role: [String?]
    let state: [State]
    let include: [Include]
    let userId: String?
    let gradingPeriodId: Int?
    let enrollmentTermId: Int?
    let sisAccountId: [String?]
    let sisCourseId: [String?]
    let sisSectionId: [String?]
    let sisUserId: [String?]
    let createdForSisId: [Bool?]
    let perPage: Int

    init(
        courseId: String,
        courseEnrollmentTermId: Int? = nil,
        type: [EnrollmentType] = [],
        role: [String?] = [],
        state: [State] = [],
        include: [Include] = [],
        userId: String? = nil,
        gradingPeriodId: Int? = nil,
        enrollmentTermId: Int? = nil,
        sisAccountId: [String?] = [],
        sisCourseId: [String?] = [],
        sisSectionId: [String?] = [],
        sisUserId: [String?] = [],
        createdForSisId: [Bool?] = [],
        perPage: Int = 50
    ) {
        self.courseId = courseId
        self.courseEnrollmentTermId = courseEnrollmentTermId
        self.type = type
        self.role = role
        self.state = state
        self.include = include
        self.userId = userId
        self.gradingPeriodId = gradingPeriodId
        self.enrollmentTermId = enrollmentTermId
        self.sisAccountId = sisAccountId
        self.sisCourseId = sisCourseId
        self.sisSectionId = sisSectionId
        self.sisUserId = sisUserId
        self.createdForSisId = createdForSisId
        self.perPage = perPage
    }

    // MARK: Persistence
    var requestId: Int? { courseId.asInt }
    var requestIdKey: ParentKeyPath<Enrollment, Int?> { .createWritable(\.courseID) }
    var idPredicate: Predicate<Enrollment> {
        #Predicate<Enrollment> { enrollment in
            enrollment.courseID == requestId
        }
    }

    var customPredicate: Predicate<Enrollment> {
        let requestUserId = self.userId?.asInt ?? -1

        // Break down the predicate into smaller parts
//        let typePredicate = self.type.isEmpty ? .true : Predicate<Enrollment>({ enrollment in
//            PredicateExpressions.build_contains(
//                PredicateExpressions.build_KeyPath(
//                    root: PredicateExpressions.build_Arg(self),
//                    keyPath: \.type
//                ),
//                PredicateExpressions.build_KeyPath(
//                    root: PredicateExpressions.build_Arg(enrollment),
//                    keyPath: \.type
//                )
//            ) as! any StandardPredicateExpression<Bool>
//        })

        let rolePredicate = self.role.isEmpty ? .true : Predicate<Enrollment>({ enrollment in
            PredicateExpressions.build_contains(
                PredicateExpressions.build_KeyPath(
                    root: PredicateExpressions.build_Arg(self),
                    keyPath: \.role
                ),
                PredicateExpressions.build_KeyPath(
                    root: PredicateExpressions.build_Arg(enrollment),
                    keyPath: \.role
                )
            ) as! any StandardPredicateExpression<Bool>
        })

//        let statePredicate = self.state.isEmpty ? .true : Predicate<Enrollment>({ enrollment in
//            PredicateExpressions.build_contains(
//                PredicateExpressions.build_KeyPath(
//                    root: PredicateExpressions.build_Arg(self),
//                    keyPath: \.state
//                ),
//                PredicateExpressions.build_KeyPath(
//                    root: PredicateExpressions.build_Arg(enrollment),
//                    keyPath: \.state.rawValue
//                )
//            ) as! any StandardPredicateExpression<Bool>
//        })

        let userIdPredicate = self.userId == nil ? .true : #Predicate<Enrollment> { enrollment in
            enrollment.userID == requestUserId
        }

        /*let gradingPeriodPredicate = self.gradingPeriodId == nil ? .true : Predicate<Enrollment>({ enrollment in
            PredicateExpressions.build_Equal(
                lhs: PredicateExpressions.build_KeyPath(
                    root: PredicateExpressions.build_Arg(enrollment),
                    keyPath: \.currentGradingPeriodID
                ),
                rhs: PredicateExpressions.build_KeyPath(
                    root: PredicateExpressions.build_Arg(self),
                    keyPath: \.gradingPeriodId
                )
            ) as! any StandardPredicateExpression<Bool>
        })*/

        let termPredicate = self.enrollmentTermId == nil ? .true : Predicate<Enrollment>({ _ in
            PredicateExpressions.build_Equal(
                lhs: PredicateExpressions.build_KeyPath(
                    root: PredicateExpressions.build_Arg(self),
                    keyPath: \.courseEnrollmentTermId
                ),
                rhs: PredicateExpressions.build_KeyPath(
                    root: PredicateExpressions.build_Arg(self),
                    keyPath: \.enrollmentTermId
                )
            ) as! any StandardPredicateExpression<Bool>
        })

        return #Predicate<Enrollment> { enrollment in
//            typePredicate.evaluate(enrollment) &&
            rolePredicate.evaluate(enrollment) &&
//            statePredicate.evaluate(enrollment) &&
            userIdPredicate.evaluate(enrollment) &&
            // gradingPeriodPredicate.evaluate(enrollment) &&
            termPredicate.evaluate(enrollment)
        }

    }
}

extension GetEnrollmentsRequest {
    enum Include: String {
        case avatarUrl = "avatar_url",
             groupIds = "group_ids",
             locked,
             observedUsers = "observed_users",
             canBeRemoved = "can_be_removed",
             uuid,
             currentPoints = "current_points"
    }

    enum State: String {
        case active,
             invited,
             creationPending = "creation_pending",
             deleted,
             rejected,
             completed,
             inactive,
             currentAndInvited = "current_and_invited",
             currentAndFuture = "current_and_future",
             currentFutureAndRestricted = "current_future_and_restricted",
             currentAndConcluded = "current_and_concluded"
    }

    enum EnrollmentType: String {
        case student = "StudentEnrollment",
             teacher = "TeacherEnrollment",
             teachingAssistant = "TaEnrollment",
             designer = "DesignerEnrollment",
             observer = "Observer"
    }
}
