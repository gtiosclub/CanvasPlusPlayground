//
//  Enrollment.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import Foundation

struct Enrollment: Codable, Equatable, Hashable {
    let id: Int?
    let courseID: Int?
    let sisCourseID: String?
    let courseIntegrationID: String?
    let courseSectionID: Int?
    let sectionIntegrationID: String?
    let sisAccountID: String?
    let sisSectionID: String?
    let sisUserID: String?
    let enrollmentState: String?
    let limitPrivilegesToCourseSection: Bool?
    let sisImportID: Int?
    let rootAccountID: Int?
    let type: String?
    let userID: Int?
    let associatedUserID: Int?
    let role: String?
    let roleID: Int?
    let createdAt: String?
    let updatedAt: String?
    let startAt: String?
    let endAt: String?
    let lastActivityAt: String?
    let lastAttendedAt: String?
    let totalActivityTime: Int?
    let htmlURL: String?
    let grades: Grades?
    let user: User?
    let overrideGrade: String?
    let overrideScore: Double?
    let unpostedCurrentGrade: String?
    let unpostedFinalGrade: String?
    let unpostedCurrentScore: String?
    let unpostedFinalScore: String?
    let hasGradingPeriods: Bool?
    let totalsForAllGradingPeriodsOption: Bool?
    let currentGradingPeriodTitle: String?
    let currentGradingPeriodID: Int?
    let currentPeriodOverrideGrade: String?
    let currentPeriodOverrideScore: Double?
    let currentPeriodUnpostedCurrentScore: Double?
    let currentPeriodUnpostedFinalScore: Double?
    let currentPeriodUnpostedCurrentGrade: String?
    let currentPeriodUnpostedFinalGrade: String?

    enum CodingKeys: String, CodingKey {
        case id
        case courseID = "course_id"
        case sisCourseID = "sis_course_id"
        case courseIntegrationID = "course_integration_id"
        case courseSectionID = "course_section_id"
        case sectionIntegrationID = "section_integration_id"
        case sisAccountID = "sis_account_id"
        case sisSectionID = "sis_section_id"
        case sisUserID = "sis_user_id"
        case enrollmentState = "enrollment_state"
        case limitPrivilegesToCourseSection = "limit_privileges_to_course_section"
        case sisImportID = "sis_import_id"
        case rootAccountID = "root_account_id"
        case type
        case userID = "user_id"
        case associatedUserID = "associated_user_id"
        case role
        case roleID = "role_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case startAt = "start_at"
        case endAt = "end_at"
        case lastActivityAt = "last_activity_at"
        case lastAttendedAt = "last_attended_at"
        case totalActivityTime = "total_activity_time"
        case htmlURL = "html_url"
        case grades
        case user
        case overrideGrade = "override_grade"
        case overrideScore = "override_score"
        case unpostedCurrentGrade = "unposted_current_grade"
        case unpostedFinalGrade = "unposted_final_grade"
        case unpostedCurrentScore = "unposted_current_score"
        case unpostedFinalScore = "unposted_final_score"
        case hasGradingPeriods = "has_grading_periods"
        case totalsForAllGradingPeriodsOption = "totals_for_all_grading_periods_option"
        case currentGradingPeriodTitle = "current_grading_period_title"
        case currentGradingPeriodID = "current_grading_period_id"
        case currentPeriodOverrideGrade = "current_period_override_grade"
        case currentPeriodOverrideScore = "current_period_override_score"
        case currentPeriodUnpostedCurrentScore = "current_period_unposted_current_score"
        case currentPeriodUnpostedFinalScore = "current_period_unposted_final_score"
        case currentPeriodUnpostedCurrentGrade = "current_period_unposted_current_grade"
        case currentPeriodUnpostedFinalGrade = "current_period_unposted_final_grade"
    }
}

struct Grades: Codable, Equatable, Hashable {
    let htmlURL: String?
    let currentScore: Double?
    let currentGrade: String?
    let finalScore: Double?
    let finalGrade: String?

    enum CodingKeys: String, CodingKey {
        case htmlURL = "html_url"
        case currentScore = "current_score"
        case currentGrade = "current_grade"
        case finalScore = "final_score"
        case finalGrade = "final_grade"
    }
}

struct User: Codable, Equatable, Hashable {
    let id: Int?
    let name: String?
    let sortableName: String?
    let shortName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sortableName = "sortable_name"
        case shortName = "short_name"
    }
}
