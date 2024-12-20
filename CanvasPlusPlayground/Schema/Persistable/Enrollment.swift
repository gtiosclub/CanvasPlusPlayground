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
    var enrollmentState: String?
    var limitPrivilegesToCourseSection: Bool?
    var sisImportID: Int?
    var rootAccountID: Int?
    var type: String?
    var userID: Int
    var associatedUserID: Int?
    var role: String?
    var roleID: Int?
    var createdAt: String?
    var updatedAt: String?
    var startAt: String?
    var endAt: String?
    var lastActivityAt: String?
    var lastAttendedAt: String?
    var totalActivityTime: Int?
    var htmlURL: String?
    var grades: Grades?
    var user: User?
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
        case parentID = "parent_id"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(ServerID.self, forKey: .id)
        self.id = String(describing: id)

        self.courseID = try container.decodeIfPresent(Int.self, forKey: .courseID)
        self.sisCourseID = try container.decodeIfPresent(String.self, forKey: .sisCourseID)
        self.courseIntegrationID = try container.decodeIfPresent(String.self, forKey: .courseIntegrationID)
        self.courseSectionID = try container.decodeIfPresent(Int.self, forKey: .courseSectionID)
        self.sectionIntegrationID = try container.decodeIfPresent(String.self, forKey: .sectionIntegrationID)
        self.sisAccountID = try container.decodeIfPresent(String.self, forKey: .sisAccountID)
        self.sisSectionID = try container.decodeIfPresent(String.self, forKey: .sisSectionID)
        self.sisUserID = try container.decodeIfPresent(String.self, forKey: .sisUserID)
        self.enrollmentState = try container.decodeIfPresent(String.self, forKey: .enrollmentState)
        self.limitPrivilegesToCourseSection = try container.decodeIfPresent(Bool.self, forKey: .limitPrivilegesToCourseSection)
        self.sisImportID = try container.decodeIfPresent(Int.self, forKey: .sisImportID)
        self.rootAccountID = try container.decodeIfPresent(Int.self, forKey: .rootAccountID)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        self.userID = try container.decodeIfPresent(Int.self, forKey: .userID) ?? -1
        self.associatedUserID = try container.decodeIfPresent(Int.self, forKey: .associatedUserID)
        self.role = try container.decodeIfPresent(String.self, forKey: .role)
        self.roleID = try container.decodeIfPresent(Int.self, forKey: .roleID)
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        self.startAt = try container.decodeIfPresent(String.self, forKey: .startAt)
        self.endAt = try container.decodeIfPresent(String.self, forKey: .endAt)
        self.lastActivityAt = try container.decodeIfPresent(String.self, forKey: .lastActivityAt)
        self.lastAttendedAt = try container.decodeIfPresent(String.self, forKey: .lastAttendedAt)
        self.totalActivityTime = try container.decodeIfPresent(Int.self, forKey: .totalActivityTime)
        self.htmlURL = try container.decodeIfPresent(String.self, forKey: .htmlURL)
        self.grades = try container.decodeIfPresent(Grades.self, forKey: .grades)
        self.user = try container.decodeIfPresent(User.self, forKey: .user)
        self.overrideGrade = try container.decodeIfPresent(String.self, forKey: .overrideGrade)
        self.overrideScore = try container.decodeIfPresent(Double.self, forKey: .overrideScore)
        self.unpostedCurrentGrade = try container.decodeIfPresent(String.self, forKey: .unpostedCurrentGrade)
        self.unpostedFinalGrade = try container.decodeIfPresent(String.self, forKey: .unpostedFinalGrade)
        self.unpostedCurrentScore = try container.decodeIfPresent(String.self, forKey: .unpostedCurrentScore)
        self.unpostedFinalScore = try container.decodeIfPresent(String.self, forKey: .unpostedFinalScore)
        self.hasGradingPeriods = try container.decodeIfPresent(Bool.self, forKey: .hasGradingPeriods)
        self.totalsForAllGradingPeriodsOption = try container.decodeIfPresent(Bool.self, forKey: .totalsForAllGradingPeriodsOption)
        self.currentGradingPeriodTitle = try container.decodeIfPresent(String.self, forKey: .currentGradingPeriodTitle)
        self.currentGradingPeriodID = try container.decodeIfPresent(Int.self, forKey: .currentGradingPeriodID)
        self.currentPeriodOverrideGrade = try container.decodeIfPresent(String.self, forKey: .currentPeriodOverrideGrade)
        self.currentPeriodOverrideScore = try container.decodeIfPresent(Double.self, forKey: .currentPeriodOverrideScore)
        self.currentPeriodUnpostedCurrentScore = try container.decodeIfPresent(Double.self, forKey: .currentPeriodUnpostedCurrentScore)
        self.currentPeriodUnpostedFinalScore = try container.decodeIfPresent(Double.self, forKey: .currentPeriodUnpostedFinalScore)
        self.currentPeriodUnpostedCurrentGrade = try container.decodeIfPresent(String.self, forKey: .currentPeriodUnpostedCurrentGrade)
        self.currentPeriodUnpostedFinalGrade = try container.decodeIfPresent(String.self, forKey: .currentPeriodUnpostedFinalGrade)
        self.parentId = try container
            .decodeIfPresent(String.self, forKey: .parentID) ?? ""
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(courseID, forKey: .courseID)
        try container.encodeIfPresent(sisCourseID, forKey: .sisCourseID)
        try container.encodeIfPresent(courseIntegrationID, forKey: .courseIntegrationID)
        try container.encodeIfPresent(courseSectionID, forKey: .courseSectionID)
        try container.encodeIfPresent(sectionIntegrationID, forKey: .sectionIntegrationID)
        try container.encodeIfPresent(sisAccountID, forKey: .sisAccountID)
        try container.encodeIfPresent(sisSectionID, forKey: .sisSectionID)
        try container.encodeIfPresent(sisUserID, forKey: .sisUserID)
        try container.encodeIfPresent(enrollmentState, forKey: .enrollmentState)
        try container.encodeIfPresent(limitPrivilegesToCourseSection, forKey: .limitPrivilegesToCourseSection)
        try container.encodeIfPresent(sisImportID, forKey: .sisImportID)
        try container.encodeIfPresent(rootAccountID, forKey: .rootAccountID)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(userID, forKey: .userID)
        try container.encodeIfPresent(associatedUserID, forKey: .associatedUserID)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encodeIfPresent(roleID, forKey: .roleID)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(startAt, forKey: .startAt)
        try container.encodeIfPresent(endAt, forKey: .endAt)
        try container.encodeIfPresent(lastActivityAt, forKey: .lastActivityAt)
        try container.encodeIfPresent(lastAttendedAt, forKey: .lastAttendedAt)
        try container.encodeIfPresent(totalActivityTime, forKey: .totalActivityTime)
        try container.encodeIfPresent(htmlURL, forKey: .htmlURL)
        try container.encodeIfPresent(grades, forKey: .grades)
        try container.encodeIfPresent(user, forKey: .user)
        try container.encodeIfPresent(overrideGrade, forKey: .overrideGrade)
        try container.encodeIfPresent(overrideScore, forKey: .overrideScore)
        try container.encodeIfPresent(unpostedCurrentGrade, forKey: .unpostedCurrentGrade)
        try container.encodeIfPresent(unpostedFinalGrade, forKey: .unpostedFinalGrade)
        try container.encodeIfPresent(unpostedCurrentScore, forKey: .unpostedCurrentScore)
        try container.encodeIfPresent(unpostedFinalScore, forKey: .unpostedFinalScore)
        try container.encodeIfPresent(hasGradingPeriods, forKey: .hasGradingPeriods)
        try container.encodeIfPresent(totalsForAllGradingPeriodsOption, forKey: .totalsForAllGradingPeriodsOption)
        try container.encodeIfPresent(currentGradingPeriodTitle, forKey: .currentGradingPeriodTitle)
        try container.encodeIfPresent(currentGradingPeriodID, forKey: .currentGradingPeriodID)
        try container.encodeIfPresent(currentPeriodOverrideGrade, forKey: .currentPeriodOverrideGrade)
        try container.encodeIfPresent(currentPeriodOverrideScore, forKey: .currentPeriodOverrideScore)
        try container.encodeIfPresent(currentPeriodUnpostedCurrentScore, forKey: .currentPeriodUnpostedCurrentScore)
        try container.encodeIfPresent(currentPeriodUnpostedFinalScore, forKey: .currentPeriodUnpostedFinalScore)
        try container.encodeIfPresent(currentPeriodUnpostedCurrentGrade, forKey: .currentPeriodUnpostedCurrentGrade)
        try container.encodeIfPresent(currentPeriodUnpostedFinalGrade, forKey: .currentPeriodUnpostedFinalGrade)
        try container.encodeIfPresent(parentId, forKey: .parentID)
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
    var role: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sortableName = "sortable_name"
        case shortName = "short_name"
    }

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
