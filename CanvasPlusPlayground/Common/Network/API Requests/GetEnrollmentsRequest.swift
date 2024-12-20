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
        return #Predicate<Enrollment> { enrollment in
            (self.type.isEmpty || self.type.contains(enrollment.type)) &&
            (self.role.isEmpty || self.role.contains(enrollment.role)) &&
            (self.state.isEmpty || self.state.contains(enrollment.enrollmentState)) &&
            (self.userId == nil || enrollment.userID == requestUserId) &&
            (self.gradingPeriodId == nil || enrollment.currentGradingPeriodID == self.gradingPeriodId) &&
            (self.enrollmentTermId == nil || self.courseEnrollmentTermId == self.enrollmentTermId) &&
            (self.sisAccountId.isEmpty || self.sisAccountId.contains(enrollment.sisAccountID)) &&
            (self.sisCourseId.isEmpty || self.sisCourseId.contains(enrollment.sisCourseID)) &&
            (self.sisSectionId.isEmpty || self.sisSectionId.contains(enrollment.sisSectionID)) &&
            (self.sisUserId.isEmpty || self.sisUserId.contains(enrollment.sisUserID))
        }
    }
}
