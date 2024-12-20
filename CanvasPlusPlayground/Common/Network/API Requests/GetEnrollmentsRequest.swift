//
//  GetEnrollmentsRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/20/24.
//

import Foundation

struct GetEnrollmentsRequest: ArrayAPIRequest {
    typealias Subject = Enrollment
    
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
    let type: [String?]
    let role: [String?]
    let state: [String?]
    let include: [String?]
    let userId: String?
    let gradingPeriodId: Int?
    let enrollmentTermId: Int?
    let sisAccountId: [String?]
    let sisCourseId: [String?]
    let sisSectionId: [String?]
    let sisUserId: [String?]
    let createdForSisId: [Bool?]
    let perPage: Int
    
    // MARK: Persistence
    var requestId: Int? { courseId.asInt }
    var requestIdKey: ParentKeyPath<Enrollment, Int?> { .createWritable(\.courseID) }
    var customPredicate: Predicate<Enrollment> {
        let requestUserId = self.userId?.asInt ?? -1
        // TODO: fix predicate here
        return .true
        /*
        // Break down the predicate into smaller parts
        let typePredicate = (self.type.isEmpty ? .true : Predicate<Enrollment> { enrollment in
            self.type.contains(enrollment.type) as! any StandardPredicateExpression<Bool>
        })

        let rolePredicate = (self.role.isEmpty ? .true : Predicate<Enrollment> { enrollment in
            self.role.contains(enrollment.role)  as! any StandardPredicateExpression<Bool>
        })

        let statePredicate = (self.state.isEmpty ? .true : Predicate<Enrollment> { enrollment in
            self.state.contains(enrollment.enrollmentState) as! any StandardPredicateExpression<Bool>
        })

        let userIdPredicate = self.userId == nil ? .true : Predicate<Enrollment> { enrollment in
            enrollment.userID == requestUserId as! any StandardPredicateExpression<Bool>
        }

        let gradingPeriodPredicate = self.gradingPeriodId == nil ? .true : Predicate<Enrollment> { enrollment in
            enrollment.currentGradingPeriodID == self.gradingPeriodId
        }

        let termPredicate = self.enrollmentTermId == nil ? .true : Predicate<Enrollment> { enrollment in
            self.courseEnrollmentTermId == self.enrollmentTermId
        }
        
        return Predicate<Enrollment> { enrollment in

            // Combine predicates into one using logical operators
            return #Predicate<Enrollment> { enrollment in
                typePredicate.evaluate(enrollment) &&
                rolePredicate.evaluate(enrollment) &&
                statePredicate.evaluate(enrollment) &&
                userIdPredicate.evaluate(enrollment) &&
                gradingPeriodPredicate.evaluate(enrollment) &&
                termPredicate.evaluate(enrollment)
            }.evaluate(enrollment)
        }*/
    }
}
