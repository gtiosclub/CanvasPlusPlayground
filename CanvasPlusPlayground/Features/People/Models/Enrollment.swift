//
//  Enrollment.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import Foundation
import SwiftData

typealias Enrollment = CanvasSchemaV1.Enrollment

extension CanvasSchemaV1 {
    @Model
    final class Enrollment {
        typealias ID = String
        typealias ServerID = Int

        @Attribute(.unique)
        let id: String
        var courseID: Int?
    //    var sisCourseID: String?
    //    var courseIntegrationID: String?
        var courseSectionID: Int?
    //    var sectionIntegrationID: String?
    //    var sisAccountID: String?
    //    var sisSectionID: String?
    //    var sisUserID: String?
        var state: EnrollmentState?
    //    var limitPrivilegesToCourseSection: Bool?
    //    var sisImportID: Int?
    //    var rootAccountID: Int?
        var type: String?
        var userID: Int
        var associatedUserID: Int?
        var role: String?
        var roleID: Int?
    //    var createdAt: String?
    //    var updatedAt: String?
        var startAt: Date?
        var endAt: Date?
        var lastActivityAt: Date?
    //    var lastAttendedAt: Date?
    //    var totalActivityTime: Int?
    //    var htmlURL: String?
        var grades: Grades?
        var user: UserAPI?
    //    var overrideGrade: String?
    //    var overrideScore: Double?
    //    var unpostedCurrentGrade: String?
    //    var unpostedFinalGrade: String?
    //    var unpostedCurrentScore: String?
    //    var unpostedFinalScore: String?
    //    var hasGradingPeriods: Bool?
    //    var totalsForAllGradingPeriodsOption: Bool?
    //    var currentGradingPeriodTitle: String?
    //    var currentGradingPeriodID: Int?
    //    var currentPeriodOverrideGrade: String?
    //    var currentPeriodOverrideScore: Double?
    //    var currentPeriodUnpostedCurrentScore: Double?
    //    var currentPeriodUnpostedFinalScore: Double?
    //    var currentPeriodUnpostedCurrentGrade: String?
    //    var currentPeriodUnpostedFinalGrade: String?

        // MARK: Custom Properties
        var displayRole: String? {
            role?.replacingOccurrences(of: "Enrollment", with: "")
        }

        init(from enrollmentAPI: EnrollmentAPI) {
            self.id = enrollmentAPI.id.asString
            self.courseID = enrollmentAPI.course_id
            self.courseSectionID = enrollmentAPI.course_section_id
            self.state = enrollmentAPI.enrollment_state
            self.type = enrollmentAPI.type
            self.userID = enrollmentAPI.user_id
            self.associatedUserID = enrollmentAPI.associated_user_id
            self.role = enrollmentAPI.role
            self.roleID = enrollmentAPI.role_id
            self.startAt = enrollmentAPI.start_at
            self.endAt = enrollmentAPI.end_at
            self.lastActivityAt = enrollmentAPI.last_activity_at
            self.grades = enrollmentAPI.grades
            self.user = enrollmentAPI.user
        }
    }
}

extension Enrollment: Cacheable {
    func merge(with other: Enrollment) {
        self.courseID = other.courseID
        self.courseSectionID = other.courseSectionID
        self.state = other.state
        self.type = other.type
        self.userID = other.userID
        self.associatedUserID = other.associatedUserID
        self.role = other.role
        self.roleID = other.roleID
        self.startAt = other.startAt
        self.endAt = other.endAt
        self.lastActivityAt = other.lastActivityAt
        self.grades = other.grades
        self.user = other.user
    }
}
