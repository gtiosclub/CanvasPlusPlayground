//
//  EnrollmentAPI.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/22/24.
//

import Foundation

// https://canvas.instructure.com/doc/api/enrollments.html
// https://github.com/instructure/canvas-ios/blob/49a3e347116d623638c66b7adbcc946294faa212/Core/Core/Enrollments/APIEnrollment.swift
struct EnrollmentAPI: APIResponse {
    typealias Model = Enrollment

    // swiftlint:disable identifier_name
    let id: Int
    let course_id: Int?
    // let sis_course_id: String?
    // let course_integration_id: String?
    let course_section_id: Int?
    // let section_integration_id: String?
    // let sis_account_id: String?
    // let sis_section_id: String?
    // let sis_user_id: String?
    let enrollment_state: EnrollmentState
    // let limit_privileges_to_course_section: Bool?
    // let sis_import_id: String?
    // let root_account_id: String
    let type: String
    let user_id: Int
    let associated_user_id: Int?
    let role: String
    let role_id: Int
    // let created_at: Date
    // let updated_at: Date
    let start_at: Date?
    let end_at: Date?
    let last_activity_at: Date?
    // let last_attended_at: Date?
    // let total_activity_time: TimeInterval
    // let html_url: String
    let grades: Grades?
    let user: UserAPI?
    let computed_current_score: Double?
    let computed_final_score: Double?
    let computed_current_grade: String?
    let computed_current_letter_grade: String?
    let computed_final_grade: String?
    // let unposted_current_grade: String?
    // let unposted_final_grade: String?
    // let unposted_current_score: String?
    // let unposted_final_score: String?
    // let has_grading_periods: Bool?
    let multiple_grading_periods_enabled: Bool?
    let totals_for_all_grading_periods_option: Bool?
    // let current_grading_period_title: String?
    let current_grading_period_id: String?
    let current_period_computed_current_score: Double?
    let current_period_computed_final_score: Double?
    let current_period_computed_current_grade: String?
    let current_period_computed_final_grade: String?
    // let current_period_unposted_current_score: Double?
    // let current_period_unposted_final_score: Double?
    // let current_period_unposted_current_grade: String?
    // let current_period_unposted_final_grade: String?

    let observed_user: UserAPI?

    func createModel() -> Enrollment {
        Enrollment(from: self)
    }
}

// https://canvas.instructure.com/doc/api/enrollments.html#Grade
public struct Grades: Codable, Equatable, Hashable {
    let htmlURL: String
    let currentGrade: String?
    let finalGrade: String?
    let currentScore: Double?
    let finalScore: Double?
    let overrideGrade: String?
    let overrideScore: Double?
    let unpostedCurrentGrade: String?
    let unpostedCurrentScore: Double?
    // let unpostedFinalGrade: String?
    // let unpostedFinalScore: Double?

    enum CodingKeys: String, CodingKey {
        case htmlURL = "html_url"
        case currentGrade = "current_grade"
        case finalGrade = "final_grade"
        case currentScore = "current_score"
        case finalScore = "final_score"
        case overrideGrade = "override_grade"
        case overrideScore = "override_score"
        case unpostedCurrentGrade = "unposted_current_grade"
        case unpostedCurrentScore = "unposted_current_score"
        // case unpostedFinalGrade = "unposted_final_grade"
        // case unpostedFinalScore = "unposted_final_score"
    }
}

public enum EnrollmentState: String, Codable, CaseIterable {
    case active, inactive, invited, completed, creation_pending, rejected, deleted
}

// swiftlint:enable identifier_name
