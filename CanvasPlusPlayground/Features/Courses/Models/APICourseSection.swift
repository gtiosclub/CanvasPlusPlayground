//
//  APICourseSection.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/23/24.
//

import Foundation

//https://canvas.instructure.com/doc/api/sections.html
struct APICourseSection: Codable, Equatable {
    // swiftlint:disable identifier_name
    let id: Int
    let name: String
    // let sis_section_id: String?
    // let integration_id: String?
    // let sis_import_id: String?
    let course_id: Int
    // let sis_course_id: String?
    let start_at: Date?
    let end_at: Date?
    // let restrict_enrollments_to_section_dates: Bool?
    // let nonxlist_course_id: String?
    let total_students: Int?
    // swiftlint:enable identifier_name

    static func create(from section: CourseAPI.SectionRef, courseID: Int) -> Self {
        .init(
            id: section.id,
            name: section.name,
            course_id: courseID,
            start_at: section.start_at,
            end_at: section.end_at,
            total_students: nil
        )
    }
}
