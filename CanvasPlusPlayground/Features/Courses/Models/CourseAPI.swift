//
//  CourseAPI.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/22/24.
//

import Foundation

// swiftlint:disable commented_code identifier_name
// https://canvas.instructure.com/doc/api/courses.html
struct CourseAPI: APIResponse, Identifiable {
    typealias Model = Course

    let id: Int
    // let sis_course_id: String?
    // let uuid: String?
    // let integration_id: String?
    // let sis_import_id: String?
    let name: String?
    let course_code: String?
    let original_name: String?
    /** Teacher assigned course color for K5 in hex format. */
    let course_color: String?
    let workflow_state: CourseState?
    let account_id: Int?
    // let root_account_id: String?
    // let enrollment_term_id: String?
    // var grading_periods: [GradingPeriod]?
    // let grading_standard_id: Int?
    // let grade_passback_setting: String?
    let created_at: Date?
    let start_at: Date?
    let end_at: Date?
    let locale: String?
    var enrollments: [CourseEnrollment]? // include[]=total_scores to also have grading info in student enrollments
    let total_students: Int? // include[]=total_students
    let calendar: CalendarLink?
    let default_view: CourseDefaultView?
    let syllabus_body: String? // include[]=syllabus_body
    // let needs_grading_count: Int? // include[]=needs_grading_count & user must have grading rights
    let term: CourseTermAPI? // include[]=term
    let course_progress: CourseProgressAPI? // include[]=course_progress
    let apply_assignment_group_weights: Bool?
    let teachers: [CourseTeacher]? // include[]=teachers
    //let account: ? // include[]=account
    let permissions: CoursePermissions?
    let is_public: Bool?
    // let is_public_to_auth_users: Bool?
    let homeroom_course: Bool?
    // let public_syllabus: Bool?
    // let public_syllabus_to_auth: Bool?
    let public_description: String? // include[]=public_description
    // let storage_quota_mb: Double?
    // let storage_quota_used_mb: Double? // include[]=storage_quota_used_mb
    let hide_final_grades: Bool?
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
    let blueprint: Bool?
    // let blueprint_restrictions: ?
    // let blueprint_restrictions_by_object_type: ?
    let banner_image_download_url: String?
    let image_download_url: String? // include[]=course_image, api sometimes returns an empty string instead of nil so don't use URL
    var is_favorite: Bool? // include[]=favorites
    let sections: [CourseSectionRef]? // include[]=sections
    let tabs: [TabAPI]? // include[]=tabs
    let settings: CourseSettings? // include[]=settings
    let concluded: Bool? // include[]=concluded
    /// Example format: [["A",0.94],["A-",0.9],["B+",0.87] ... ["D",0.64],["D-",0.61],["F",0.0]]
    let grading_scheme: [[TypeSafeCodable<String, Double>]]? // include[]=grading_scheme

    func createModel() -> Course {
        Course(self)
    }
}

struct CourseTeacher: Codable {
    let id: Int?
    let anonymousId: String?
    let displayName: String?
    let avatarImageUrl: URL?
    let htmlUrl: URL?
    let pronouns: String?

    enum CodingKeys: String, CodingKey {
        case id
        case anonymousId = "anonymous_id"
        case displayName = "display_name"
        case avatarImageUrl = "avatar_image_url"
        case htmlUrl = "html_url"
        case pronouns
    }

    static let sample = CourseTeacher(
        id: 54322,
        anonymousId: "teacher_abc123",
        displayName: "Jane Smith",
        avatarImageUrl: URL(string: "https://canvas.example.edu/images/avatars/54322"),
        htmlUrl: URL(string: "https://canvas.example.edu/courses/12345/users/54322"),
        pronouns: "she/her"
    )

}

struct CourseProgressAPI: Codable {
    let requirement_count: Int?
    let requirement_completed_count: Int?
    let next_requirement_url: URL?
    let completed_at: Date?
}

struct CourseSectionRef: Codable {
    let id: Int
    let startAt: Date?
    let endAt: Date?
    let name: String?
    let enrollmentRole: EnrollmentType?

    enum CodingKeys: String, CodingKey {
        case endAt = "end_at"
        case id
        case name
        case startAt = "start_at"
        case enrollmentRole = "enrollment_role"
    }

    static let sample = CourseSectionRef(
        id: 5678,
        startAt: Date.now.addingTimeInterval(-5184000),
        endAt: Date.now.addingTimeInterval(5184000),
        name: "Section A",
        enrollmentRole: .student
    )

    static let sample2 = CourseSectionRef(
        id: 5679,
        startAt: Date.now.addingTimeInterval(-5184000),
        endAt: Date.now.addingTimeInterval(5184000),
        name: "Section B",
        enrollmentRole: .student
    )
}

struct CourseEnrollment: Codable {
    let type: String?
    let role: String?
    let roleId: Int?
    let userId: Int?
    let enrollmentState: EnrollmentState?
    let limitPrivilegesToCourseSection: Bool?

    enum CodingKeys: String, CodingKey {
        case type
        case role
        case roleId = "role_id"
        case userId = "user_id"
        case enrollmentState = "enrollment_state"
        case limitPrivilegesToCourseSection = "limit_privileges_to_course_section"
    }
}

struct CourseTermAPI: Codable {
    let id: Int?
    let name: String?
    let start_at: Date?
    let end_at: Date?
    let created_at: Date?
    let workflow_state: WorkflowState?
    let grading_period_group_id: Int?

    enum WorkflowState: String, Codable {
        case active, deleted
    }
}

struct CoursePermissions: Codable {
    let createAnnouncement: Bool?
    let createDiscussionTopic: Bool?

    enum CodingKeys: String, CodingKey {
        case createAnnouncement = "create_announcement"
        case createDiscussionTopic = "create_discussion_topic"
    }
}

struct CalendarLink: Codable, Hashable {
    let ics: String?
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

enum CourseState: String, Codable {
    case available, completed, deleted, unpublished
}

struct CourseSettings: Codable {
    let usageRightsRequired: Bool?
    let syllabusCourseSummary: Bool?
    let restrictQuantitativeData: Bool?

    enum CodingKeys: String, CodingKey {
        case usageRightsRequired = "usage_rights_required"
        case syllabusCourseSummary = "syllabus_course_summary"
        case restrictQuantitativeData = "restrict_quantitative_data"
    }
}


extension CourseAPI {
    static let sample = CourseAPI(
            id: 12345,
            name: "Introduction to Computer Science",
            course_code: "CS101",
            original_name: "CS 101: Introduction to Computer Science",
            course_color: "#0077B6",
            workflow_state: .available,
            account_id: 5432,
            created_at: Date.now.addingTimeInterval(-7776000), // 90 days ago
            start_at: Date.now.addingTimeInterval(-5184000),   // 60 days ago
            end_at: Date.now.addingTimeInterval(5184000),     // 60 days in future
            locale: "en",
            enrollments: [
                CourseEnrollment(
                    type: "student",
                    role: "StudentEnrollment",
                    roleId: 3,
                    userId: 54321,
                    enrollmentState: .active,
                    limitPrivilegesToCourseSection: true
                ),
                CourseEnrollment(
                    type: "teacher",
                    role: "TeacherEnrollment",
                    roleId: 4,
                    userId: 54322,
                    enrollmentState: .active,
                    limitPrivilegesToCourseSection: false
                )
            ],
            total_students: 32,
            calendar: CalendarLink(ics: "https://canvas.example.edu/feeds/calendars/course_12345.ics"),
            default_view: .modules,
            syllabus_body: "<p>This course introduces the fundamentals of computer science and programming.</p>",
            term: CourseTermAPI(
                id: 876,
                name: "Spring 2025",
                start_at: Date.now.addingTimeInterval(-5184000),
                end_at: Date.now.addingTimeInterval(5184000),
                created_at: Date.now.addingTimeInterval(-10368000),
                workflow_state: .active,
                grading_period_group_id: 123
            ),
            course_progress: CourseProgressAPI(
                requirement_count: 15,
                requirement_completed_count: 7,
                next_requirement_url: URL(
                    string: "https://canvas.example.edu/courses/12345/modules/items/456"
                ),
                completed_at: nil
            ),
            apply_assignment_group_weights: true,
            teachers: [
                .sample
            ],
            permissions: CoursePermissions(
                createAnnouncement: true,
                createDiscussionTopic: true
            ),
            is_public: false,
            homeroom_course: false,
            public_description: "An introductory course to computer science concepts and programming fundamentals.",
            hide_final_grades: false,
            access_restricted_by_date: false,
            blueprint: false,
            banner_image_download_url: "https://canvas.example.edu/images/banners/cs101.jpg",
            image_download_url: "https://canvas.example.edu/images/courses/cs101.jpg",
            is_favorite: true,
            sections: [
                .sample,
                .sample2
            ],
            tabs: [
                .sample1,
                .sample2,
                .sample3
            ],
            settings: CourseSettings(
                usageRightsRequired: true,
                syllabusCourseSummary: true,
                restrictQuantitativeData: false
            ),
            concluded: false,
            grading_scheme: [
                [TypeSafeCodable(value1: "A", value2: nil), TypeSafeCodable(value1: nil, value2: 0.94)],
                [TypeSafeCodable(value1: "A-", value2: nil), TypeSafeCodable(value1: nil, value2: 0.90)],
                [TypeSafeCodable(value1: "B+", value2: nil), TypeSafeCodable(value1: nil, value2: 0.87)],
                [TypeSafeCodable(value1: "B", value2: nil), TypeSafeCodable(value1: nil, value2: 0.84)],
                [TypeSafeCodable(value1: "B-", value2: nil), TypeSafeCodable(value1: nil, value2: 0.80)],
                [TypeSafeCodable(value1: "C+", value2: nil), TypeSafeCodable(value1: nil, value2: 0.77)],
                [TypeSafeCodable(value1: "C", value2: nil), TypeSafeCodable(value1: nil, value2: 0.74)],
                [TypeSafeCodable(value1: "C-", value2: nil), TypeSafeCodable(value1: nil, value2: 0.70)],
                [TypeSafeCodable(value1: "D+", value2: nil), TypeSafeCodable(value1: nil, value2: 0.67)],
                [TypeSafeCodable(value1: "D", value2: nil), TypeSafeCodable(value1: nil, value2: 0.64)],
                [TypeSafeCodable(value1: "D-", value2: nil), TypeSafeCodable(value1: nil, value2: 0.61)],
                [TypeSafeCodable(value1: "F", value2: nil), TypeSafeCodable(value1: nil, value2: 0.0)]
            ]
        )

    /// A minimal sample with just required fields
    static let minimalSample = CourseAPI(
            id: 54321,
            name: "Minimal Course Example",
            course_code: "MIN101",
            original_name: "Minimal Course",
            course_color: "#FF5733",
            workflow_state: .available,
            account_id: nil,
            created_at: Date.now,
            start_at: nil,
            end_at: nil,
            locale: nil,
            enrollments: nil,
            total_students: nil,
            calendar: nil,
            default_view: nil,
            syllabus_body: nil,
            term: nil,
            course_progress: nil,
            apply_assignment_group_weights: nil,
            teachers: nil,
            permissions: nil,
            is_public: nil,
            homeroom_course: nil,
            public_description: nil,
            hide_final_grades: nil,
            access_restricted_by_date: nil,
            blueprint: false,
            banner_image_download_url: nil,
            image_download_url: nil,
            is_favorite: false,
            sections: nil,
            tabs: nil,
            settings: nil,
            concluded: nil,
            grading_scheme: nil
        )
}

