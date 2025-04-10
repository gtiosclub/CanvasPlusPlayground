//
//  CourseSection.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 4/3/25.
//

import Foundation

struct CourseSection: Codable, Equatable {
    let id: Int
    let name: String?
    // let sis_section_id: String?
    // let integration_id: String?
    // let sis_import_id: String?
    let courseId: Int
    // let sis_course_id: String?
    let startAt: Date?
    let endAt: Date?
    // let restrict_enrollments_to_section_dates: Bool?
    // let nonxlist_course_id: String?
    let totalStudents: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case courseId = "course_id"
        case startAt = "start_at"
        case endAt = "end_at"
        case totalStudents = "total_students"
    }

    static func create(from section: CourseSectionRef, courseID: Int) -> Self {
        .init(
            id: section.id,
            name: section.name,
            courseId: courseID,
            startAt: section.startAt,
            endAt: section.endAt,
            totalStudents: nil
        )
    }
}
