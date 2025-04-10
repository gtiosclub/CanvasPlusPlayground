//
//  Course.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import Foundation
import SwiftData

// swiftlint:disable commented_code
@Model
final class Course: Cacheable {
    // MARK: IDs
    @Attribute(.unique) var id: String
    var parentId: String

    // MARK: Other
    var name: String?
    var courseCode: String?
    var originalName: String?
    var courseColor: String?
    var workflowState: CourseState?
    var accountId: Int?
    var createdAt: Date?
    var startAt: Date?
    var endAt: Date?
    var locale: String?

    // MARK: Enrollment info
    var enrollments: [CourseEnrollment]
    var enrollmentTypesRaw: String
    var enrollmentRolesRaw: String // (var roles)
    var enrollmentRoleIds: String
    var enrollmentUserIds: String
    var enrollmentStatesRaw: String

    var totalStudents: Int?
    var calendarIcs: String?
    var defaultView: CourseDefaultView?
    var syllabusBody: String?
    var term: CourseTerm?
    var courseProgress: CourseProgress?
    var applyAssignmentGroupWeights: Bool?
    var teachers: [CourseTeacher]
    var canCreateAnnouncement: Bool?
    var canCreateDiscussionTopic: Bool?
    var isPublic: Bool?
    var isHomeroomCourse: Bool?
    var publicDescription: String?
    var hideFinalGrades: Bool?

    var accessRestrictedByDate: Bool?
    var blueprint: Bool?
    var bannerImageDownloadURL: URL?
    var imageDownloadURL: URL?
    var isFavorite: Bool
    var sections: [CourseSectionRef]
    @Relationship(deleteRule: .cascade) var tabs: [CanvasTab] = []
    var settings: CourseSettings?
    var concluded: Bool?
    var gradingScheme: [GradingSchemeEntry]

    /** Teacher assigned course color for K5 in hex format. */
    // var contextColor: ContextColor?

    var isCourseDeleted: Bool
    /** Use with caution! This property doesn't take section dates or the actual enrollment's concluded state into account. */
    var isPastEnrollment: Bool
    var isPublished: Bool
    // var roles: String? (see enrollmentRolesRaw)

    // MARK: Custom Properties
    // We cannot use `Color` directly because it needs to conform to `PersistentModel`
    var rgbColors: RGBColors?
    var nickname: String?
    var isHidden: Bool?
    var order: Int = -1 // -1 necessary for predicate filtering

    var displayName: String {
        nickname ?? name ?? "Unknown Name"
    }

    init(_ courseAPI: CourseAPI) {
        self.id = String(describing: courseAPI.id)
        self.parentId = ""

        self.name = courseAPI.name
        self.courseCode = courseAPI.course_code
        self.workflowState = courseAPI.workflow_state
        self.accountId = courseAPI.account_id
        self.createdAt = courseAPI.created_at
        self.startAt = courseAPI.start_at
        self.endAt = courseAPI.end_at
        self.locale = courseAPI.locale

        // Extra enrollments setup
        let enrollments = courseAPI.enrollments ?? []
        self.enrollments = enrollments
        self.enrollmentTypesRaw = enrollments.compactMap(\.type).joined(separator: ",")
        self.enrollmentRolesRaw = enrollments.compactMap(\.role).joined(separator: ",")
        self.enrollmentRoleIds = enrollments.compactMap(\.roleId?.asString).joined(separator: ",")
        self.enrollmentUserIds = enrollments.compactMap(\.userId?.asString).joined(separator: ",")
        self.enrollmentStatesRaw = enrollments.compactMap(\.enrollmentState?.rawValue).joined(separator: ",")

        self.totalStudents = courseAPI.total_students
        self.calendarIcs = courseAPI.calendar?.ics
        self.defaultView = courseAPI.default_view
        self.syllabusBody = courseAPI.syllabus_body
        self.term = courseAPI.term
        self.courseProgress = courseAPI.course_progress
        self.applyAssignmentGroupWeights = courseAPI.apply_assignment_group_weights
        self.teachers = courseAPI.teachers ?? []
        self.canCreateAnnouncement = courseAPI.permissions?.createAnnouncement
        self.canCreateDiscussionTopic = courseAPI.permissions?.createDiscussionTopic
        self.isPublic = courseAPI.is_public
        self.isHomeroomCourse = courseAPI.homeroom_course
        self.publicDescription = courseAPI.public_description
        self.hideFinalGrades = courseAPI.hide_final_grades

        self.accessRestrictedByDate = courseAPI.access_restricted_by_date
        self.blueprint = courseAPI.blueprint
        self.bannerImageDownloadURL = URL(string: courseAPI.banner_image_download_url ?? "")
        self.imageDownloadURL = URL(string: courseAPI.image_download_url ?? "")

        self.isFavorite = courseAPI.is_favorite ?? false
        self.sections = courseAPI.sections ?? []
        self.tabs = [] // NOTE: tabs should not be filled via initializer since @Relationship objs only persist after the parent `Course` is inserted
        self.settings = courseAPI.settings
        self.concluded = courseAPI.concluded
        self.gradingScheme = courseAPI.grading_scheme?.compactMap { GradingSchemeEntry(courseGradingScheme: $0) } ?? []
        self.courseCode = courseAPI.course_code
        self.courseColor = courseAPI.course_color
        self.bannerImageDownloadURL = URL(string: courseAPI.banner_image_download_url ?? "")

        // States as bool (business logic from https://github.com/instructure/canvas-ios/blob/master/Core/Core/Features/Courses/Course.swift)
        self.isCourseDeleted = courseAPI.workflow_state == .deleted
        self.isPastEnrollment = (
            courseAPI.workflow_state == .completed ||
            (courseAPI.end_at ?? .distantFuture) < .now ||
            (courseAPI.term?.endAt ?? .distantFuture) < .now
        )
        self.isPublished = courseAPI.workflow_state == .available || courseAPI.workflow_state == .completed
    }

    func merge(with other: Course) {
        self.name = other.name
        self.courseCode = other.courseCode
        self.originalName = other.originalName
        self.courseColor = other.courseColor
        self.workflowState = other.workflowState
        self.accountId = other.accountId
        self.createdAt = other.createdAt
        self.startAt = other.startAt
        self.endAt = other.endAt
        self.locale = other.locale

        // MARK: Enrollment info
        self.enrollments = other.enrollments
        self.enrollmentTypesRaw = other.enrollmentTypesRaw
        self.enrollmentRolesRaw = other.enrollmentRolesRaw
        self.enrollmentRoleIds = other.enrollmentRoleIds
        self.enrollmentUserIds = other.enrollmentUserIds
        self.enrollmentStatesRaw = other.enrollmentStatesRaw

        self.totalStudents = other.totalStudents
        self.calendarIcs = other.calendarIcs
        self.defaultView = other.defaultView
        self.syllabusBody = other.syllabusBody
        self.term = other.term
        self.courseProgress = other.courseProgress
        self.applyAssignmentGroupWeights = other.applyAssignmentGroupWeights
        self.teachers = other.teachers
        self.canCreateAnnouncement = other.canCreateAnnouncement
        self.canCreateDiscussionTopic = other.canCreateDiscussionTopic
        self.isPublic = other.isPublic
        self.isHomeroomCourse = other.isHomeroomCourse
        self.publicDescription = other.publicDescription
        self.hideFinalGrades = other.hideFinalGrades

        self.accessRestrictedByDate = other.accessRestrictedByDate
        self.blueprint = other.blueprint
        self.bannerImageDownloadURL = other.bannerImageDownloadURL
        self.imageDownloadURL = other.imageDownloadURL
        self.isFavorite = other.isFavorite
        self.sections = other.sections
        //self.tabs = other.tabs
        self.settings = other.settings
        self.concluded = other.concluded
        self.gradingScheme = other.gradingScheme

        // State properties
        self.isCourseDeleted = other.isCourseDeleted
        self.isPastEnrollment = other.isPastEnrollment
        self.isPublished = other.isPublished

        // Note: These custom properties must NOT be merged.
        // self.rgbColors = other.rgbColors
        // self.nickname = other.nickname
        // self.isHidden = other.isHidden

        self.order = other.order // assumes order is set before merging
    }
}

extension Course {
    static let sample = Course(.sample)
    static let minimalSample = Course(.minimalSample)
}
