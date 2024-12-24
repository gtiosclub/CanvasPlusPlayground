//
//  Enrollment.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import Foundation
import SwiftData

@Model
final class Enrollment: Cacheable {
    typealias ID = String
    typealias ServerID = Int

    @Attribute(.unique)
    let id: String
    var courseID: Int?
    var sisCourseID: String?
    var courseIntegrationID: String?
    var courseSectionID: Int?
    var sectionIntegrationID: String?
    var sisAccountID: String?
    var sisSectionID: String?
    var sisUserID: String?
    var enrollmentState: EnrollmentState?
    var limitPrivilegesToCourseSection: Bool?
    var sisImportID: Int?
    var rootAccountID: Int?
    var type: String?
    var userID: Int
    var associatedUserID: Int?
    var role: String?
    var roleID: String?
    var createdAt: String?
    var updatedAt: String?
    var startAt: Date?
    var endAt: Date?
    var lastActivityAt: Date?
    var lastAttendedAt: Date?
    var totalActivityTime: Int?
    var htmlURL: String?
    var grades: Grades?
    var user: UserAPI?
    var overrideGrade: String?
    var overrideScore: Double?
    var unpostedCurrentGrade: String?
    var unpostedFinalGrade: String?
    var unpostedCurrentScore: String?
    var unpostedFinalScore: String?
    var hasGradingPeriods: Bool?
    var totalsForAllGradingPeriodsOption: Bool?
    var currentGradingPeriodTitle: String?
    var currentGradingPeriodID: Int?
    var currentPeriodOverrideGrade: String?
    var currentPeriodOverrideScore: Double?
    var currentPeriodUnpostedCurrentScore: Double?
    var currentPeriodUnpostedFinalScore: Double?
    var currentPeriodUnpostedCurrentGrade: String?
    var currentPeriodUnpostedFinalGrade: String?

    // MARK: Cacheable
    var parentId: String

    // MARK: Custom Properties
    var displayRole: String? {
        role?.replacingOccurrences(of: "Enrollment", with: "")
    }

    init(from enrollmentAPI: EnrollmentAPI) throws {
        self.id = enrollmentAPI.id.asString
        self.courseID = enrollmentAPI.course_id
        self.courseSectionID = enrollmentAPI.course_section_id
        self.enrollmentState = enrollmentAPI.enrollment_state
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
        self.totalsForAllGradingPeriodsOption = enrollmentAPI.totals_for_all_grading_periods_option
        self.currentGradingPeriodID = enrollmentAPI.current_grading_period_id
        self.currentperiodcompu
    }

    func merge(with other: Enrollment) {
        courseID = other.courseID
        sisCourseID = other.sisCourseID
        courseIntegrationID = other.courseIntegrationID
        courseSectionID = other.courseSectionID
        sectionIntegrationID = other.sectionIntegrationID
        sisAccountID = other.sisAccountID
        sisSectionID = other.sisSectionID
        sisUserID = other.sisUserID
        enrollmentState = other.enrollmentState
        limitPrivilegesToCourseSection = other.limitPrivilegesToCourseSection
        sisImportID = other.sisImportID
        rootAccountID = other.rootAccountID
        type = other.type
        userID = other.userID
        associatedUserID = other.associatedUserID
        role = other.role
        roleID = other.roleID
        createdAt = other.createdAt
        updatedAt = other.updatedAt
        startAt = other.startAt
        endAt = other.endAt
        lastActivityAt = other.lastActivityAt
        lastAttendedAt = other.lastAttendedAt
        totalActivityTime = other.totalActivityTime
        htmlURL = other.htmlURL
        grades = other.grades
        user = other.user
        overrideGrade = other.overrideGrade
        overrideScore = other.overrideScore
        unpostedCurrentGrade = other.unpostedCurrentGrade
        unpostedFinalGrade = other.unpostedFinalGrade
        unpostedCurrentScore = other.unpostedCurrentScore
        unpostedFinalScore = other.unpostedFinalScore
        hasGradingPeriods = other.hasGradingPeriods
        totalsForAllGradingPeriodsOption = other.totalsForAllGradingPeriodsOption
        currentGradingPeriodTitle = other.currentGradingPeriodTitle
        currentGradingPeriodID = other.currentGradingPeriodID
        currentPeriodOverrideGrade = other.currentPeriodOverrideGrade
        currentPeriodOverrideScore = other.currentPeriodOverrideScore
        currentPeriodUnpostedCurrentScore = other.currentPeriodUnpostedCurrentScore
        currentPeriodUnpostedFinalScore = other.currentPeriodUnpostedFinalScore
        currentPeriodUnpostedCurrentGrade = other.currentPeriodUnpostedCurrentGrade
        currentPeriodUnpostedFinalGrade = other.currentPeriodUnpostedFinalGrade
    }
}
