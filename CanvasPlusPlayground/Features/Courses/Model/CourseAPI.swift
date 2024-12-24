//
//  CourseAPI.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/22/24.
//

import Foundation

struct CourseAPI: APIResponse {
    typealias Model = Course
    
    let id: Int
    // let sis_course_id: String?
    // let uuid: String?
    // let integration_id: String?
    // let sis_import_id: String?
    let name: String?
    let course_code: String?
    /** Teacher assigned course color for K5 in hex format. */
    let course_color: String?
    let workflow_state: CourseWorkflowState?
    let account_id: String?
    // let root_account_id: String?
    // let enrollment_term_id: String?
    // let grading_standard_id: String?
    let start_at: Date?
    let end_at: Date?
    let locale: String?
    var enrollments: [EnrollmentAPI]?
    var grading_periods: [APIGradingPeriod]?
    // let total_students: Int? // include[]=total_students
    // let calendar: ?
    let default_view: CourseDefaultView?
    let syllabus_body: String? // include[]=syllabus_body
    // let needs_grading_count: Int? // include[]=needs_grading_count
    let term: Term? // include[]=term
    // let course_progress: ?
    // let apply_assignment_group_weights: Bool?
    let permissions: Permissions?
    // let is_public: Bool?
    // let is_public_to_auth_users: Bool?
    // let public_syllabus: Bool?
    // let public_syllabus_to_auth: Bool?
    // let public_description: String?
    // let storage_quota_mb: Double?
    // let storage_quota_used_mb: Double? // include[]=storage_quota_used_mb
    let hide_final_grades: Bool?
    let homeroom_course: Bool?
    // let license: String?
    // let allow_student_assignment_edits: Bool?
    // let allow_wiki_comments: Bool?
    // let allow_student_forum_attachments: Bool?
    // let open_enrollment: Bool?
    // let self_enrollment: Bool?
    // let restrict_enrollments_to_course_dates: Bool?
    // let course_format: String?
    let access_restricted_by_date: Bool?
    // let time_zone: TimeZone?
    // let blueprint: Bool?
    // let blueprint_restrictions: ?
    // let blueprint_restrictions_by_object_type: ?
    let banner_image_download_url: String?
    let image_download_url: String? // include[]=course_image, api sometimes returns an empty string instead of nil so don't use URL
    var is_favorite: Bool? // include[]=favorites
    let sections: [SectionRef]? // include[]=sections
    let tabs: [TabAPI]? // include[]=tabs
    let settings: APICourseSettings? // include[]=settings
    /// Example format: [["A",0.94],["A-",0.9],["B+",0.87] ... ["D",0.64],["D-",0.61],["F",0.0]]
    let grading_scheme: [[TypeSafeCodable<String, Double>]]? // include[]=grading_scheme

    func createModel() -> Course {
        Course(self)
    }
    
    struct Term: Codable, Equatable {
        let id: ID
        let name: String
        let start_at: Date?
        let end_at: Date?
    }

    struct Permissions: Codable, Equatable {
        let create_announcement: Bool
        let create_discussion_topic: Bool
    }

    struct SectionRef: Codable, Equatable {
        let end_at: Date?
        let id: ID
        let name: String
        let start_at: Date?
    }
}

struct CalendarLink: Codable, Equatable, Hashable {
    let ics: String
}

enum CourseDefaultView: String, Codable, CaseIterable {
    case assignments, feed, modules, syllabus, wiki

    var string: String {
        switch self {
        case .assignments:
            "Assignments List"
        case .feed:
            "Course Activity Stream"
        case .modules:
            "Course Modules"
        case .syllabus:
            "Syllabus"
        case .wiki:
            "Pages Front Page"
        }
    }
}

enum CourseWorkflowState: String, Codable {
    case available, completed, deleted, unpublished
}

struct APICourseSettings: Codable, Equatable {
    let usage_rights_required: Bool?
    let syllabus_course_summary: Bool?
    let restrict_quantitative_data: Bool?
}
