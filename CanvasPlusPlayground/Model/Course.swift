//
//  Course.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

/*
 https://canvas.instructure.com/doc/api/courses.html
 A course object looks like:
 {
   // the unique identifier for the course
   "id": 370663,
   // the SIS identifier for the course, if defined. This field is only included if
   // the user has permission to view SIS information.
   "sis_course_id": null,
   // the UUID of the course
   "uuid": "WvAHhY5FINzq5IyRIJybGeiXyFkG3SqHUPb7jZY5",
   // the integration identifier for the course, if defined. This field is only
   // included if the user has permission to view SIS information.
   "integration_id": null,
   // the unique identifier for the SIS import. This field is only included if the
   // user has permission to manage SIS information.
   "sis_import_id": 34,
   // the full name of the course. If the requesting user has set a nickname for
   // the course, the nickname will be shown here.
   "name": "InstructureCon 2012",
   // the course code
   "course_code": "INSTCON12",
   // the actual course name. This field is returned only if the requesting user
   // has set a nickname for the course.
   "original_name": "InstructureCon-2012-01",
   // the current state of the course, also known as ‘status’.  The value will be
   // one of the following values: 'unpublished', 'available', 'completed', or
   // 'deleted'.  NOTE: When fetching a singular course that has a 'deleted'
   // workflow state value, an error will be returned with a message of 'The
   // specified resource does not exist.'
   "workflow_state": "available",
   // the account associated with the course
   "account_id": 81259,
   // the root account associated with the course
   "root_account_id": 81259,
   // the enrollment term associated with the course
   "enrollment_term_id": 34,
   // A list of grading periods associated with the course
   "grading_periods": null,
   // the grading standard associated with the course
   "grading_standard_id": 25,
   // the grade_passback_setting set on the course
   "grade_passback_setting": "nightly_sync",
   // the date the course was created.
   "created_at": "2012-05-01T00:00:00-06:00",
   // the start date for the course, if applicable
   "start_at": "2012-06-01T00:00:00-06:00",
   // the end date for the course, if applicable
   "end_at": "2012-09-01T00:00:00-06:00",
   // the course-set locale, if applicable
   "locale": "en",
   // A list of enrollments linking the current user to the course. for student
   // enrollments, grading information may be included if include[]=total_scores
   "enrollments": null,
   // optional: the total number of active and invited students in the course
   "total_students": 32,
   // course calendar
   "calendar": null,
   // the type of page that users will see when they first visit the course -
   // 'feed': Recent Activity Dashboard - 'wiki': Wiki Front Page - 'modules':
   // Course Modules/Sections Page - 'assignments': Course Assignments List -
   // 'syllabus': Course Syllabus Page other types may be added in the future
   "default_view": "feed",
   // optional: user-generated HTML for the course syllabus
   "syllabus_body": "<p>syllabus html goes here</p>",
   // optional: the number of submissions needing grading returned only if the
   // current user has grading rights and include[]=needs_grading_count
   "needs_grading_count": 17,
   // optional: the enrollment term object for the course returned only if
   // include[]=term
   "term": null,
   // optional: information on progress through the course returned only if
   // include[]=course_progress
   "course_progress": null,
   // weight final grade based on assignment group percentages
   "apply_assignment_group_weights": true,
   // optional: the permissions the user has for the course. returned only for a
   // single course and include[]=permissions
   "permissions": {"create_discussion_topic":true,"create_announcement":true},
   "is_public": true,
   "is_public_to_auth_users": true,
   "public_syllabus": true,
   "public_syllabus_to_auth": true,
   // optional: the public description of the course
   "public_description": "Come one, come all to InstructureCon 2012!",
   "storage_quota_mb": 5,
   "storage_quota_used_mb": 5,
   "hide_final_grades": false,
   "license": "Creative Commons",
   "allow_student_assignment_edits": false,
   "allow_wiki_comments": false,
   "allow_student_forum_attachments": false,
   "open_enrollment": true,
   "self_enrollment": false,
   "restrict_enrollments_to_course_dates": false,
   "course_format": "online",
   // optional: this will be true if this user is currently prevented from viewing
   // the course because of date restriction settings
   "access_restricted_by_date": false,
   // The course's IANA time zone name.
   "time_zone": "America/Denver",
   // optional: whether the course is set as a Blueprint Course (blueprint fields
   // require the Blueprint Courses feature)
   "blueprint": true,
   // optional: Set of restrictions applied to all locked course objects
   "blueprint_restrictions": {"content":true,"points":true,"due_dates":false,"availability_dates":false},
   // optional: Sets of restrictions differentiated by object type applied to
   // locked course objects
   "blueprint_restrictions_by_object_type": {"assignment":{"content":true,"points":true},"wiki_page":{"content":true}},
   // optional: whether the course is set as a template (requires the Course
   // Templates feature)
   "template": true
 }
 */
import Foundation
import SwiftData



@Model
class CourseDTO: DTO {
    typealias Model = Course
    
    @Attribute(.unique) var id: String
    @Attribute var data: Data
    
    init(id: Model.ID, data: Data) {
        self.id = String(describing: id)
        self.data = data
    }
    
    convenience init(model: Model) throws {
        guard let id = model.id, let data = try? JSONEncoder().encode(model) else {
            throw CacheError.encodingError
        }
        self.init(id: id, data: data)
    }

    func toModel() throws -> Model {
        return try JSONDecoder().decode(Model.self, from: self.data)
    }
}

struct Course: Cacheable {
    static var tag: String { String(describing: CachedDTO.self) }
    typealias CachedDTO = CourseDTO
    
    var id: Int?

    let sisCourseID: String?
    let uuid: String?
    let integrationID: String?
    let sisImportID: Int?
    let name: String?
    let courseCode: String?
    let originalName: String?
    let workflowState: String?
    let accountID: Int?
    let rootAccountID: Int?
    let enrollmentTermID: Int?
    let gradingPeriods: [String]?
    let gradingStandardID: Int?
    let gradePassbackSetting: String?
    let createdAt: String?
    let startAt: String?
    let endAt: String?
    let locale: String?
    let enrollments: [Enrollment]?
    let totalStudents: Int?
    let calendar: CalendarLink?
    let defaultView: String?
    let syllabusBody: String?
    let needsGradingCount: Int?
    let term: String?
    let courseProgress: String?
    let applyAssignmentGroupWeights: Bool?
    let permissions: Permissions?
    let isPublic: Bool?
    let isPublicToAuthUsers: Bool?
    let publicSyllabus: Bool?
    let publicSyllabusToAuth: Bool?
    let publicDescription: String?
    let storageQuotaMB: Int?
    let storageQuotaUsedMB: Int?
    let hideFinalGrades: Bool?
    let license: String?
    let allowStudentAssignmentEdits: Bool?
    let allowWikiComments: Bool?
    let allowStudentForumAttachments: Bool?
    let openEnrollment: Bool?
    let selfEnrollment: Bool?
    let restrictEnrollmentsToCourseDates: Bool?
    let courseFormat: String?
    let accessRestrictedByDate: Bool?
    let timeZone: String?
    let blueprint: Bool?
    let blueprintRestrictions: [String: Bool]?
    let blueprintRestrictionsByObjectType: [String: [String: Bool]]?
    let template: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case sisCourseID = "sis_course_id"
        case uuid
        case integrationID = "integration_id"
        case sisImportID = "sis_import_id"
        case name
        case courseCode = "course_code"
        case originalName = "original_name"
        case workflowState = "workflow_state"
        case accountID = "account_id"
        case rootAccountID = "root_account_id"
        case enrollmentTermID = "enrollment_term_id"
        case gradingPeriods = "grading_periods"
        case gradingStandardID = "grading_standard_id"
        case gradePassbackSetting = "grade_passback_setting"
        case createdAt = "created_at"
        case startAt = "start_at"
        case endAt = "end_at"
        case locale
        case enrollments
        case totalStudents = "total_students"
        case calendar
        case defaultView = "default_view"
        case syllabusBody = "syllabus_body"
        case needsGradingCount = "needs_grading_count"
        case term
        case courseProgress = "course_progress"
        case applyAssignmentGroupWeights = "apply_assignment_group_weights"
        case permissions
        case isPublic = "is_public"
        case isPublicToAuthUsers = "is_public_to_auth_users"
        case publicSyllabus = "public_syllabus"
        case publicSyllabusToAuth = "public_syllabus_to_auth"
        case publicDescription = "public_description"
        case storageQuotaMB = "storage_quota_mb"
        case storageQuotaUsedMB = "storage_quota_used_mb"
        case hideFinalGrades = "hide_final_grades"
        case license
        case allowStudentAssignmentEdits = "allow_student_assignment_edits"
        case allowWikiComments = "allow_wiki_comments"
        case allowStudentForumAttachments = "allow_student_forum_attachments"
        case openEnrollment = "open_enrollment"
        case selfEnrollment = "self_enrollment"
        case restrictEnrollmentsToCourseDates = "restrict_enrollments_to_course_dates"
        case courseFormat = "course_format"
        case accessRestrictedByDate = "access_restricted_by_date"
        case timeZone = "time_zone"
        case blueprint
        case blueprintRestrictions = "blueprint_restrictions"
        case blueprintRestrictionsByObjectType = "blueprint_restrictions_by_object_type"
        case template
    }
    
    func toDTO() throws -> CachedDTO {
        try CourseDTO(model: self)
    }
    
    func tag() -> String {
        Course.tag
    }
}

struct Permissions: Codable, Equatable, Hashable {
    let createDiscussionTopic: Bool
    let createAnnouncement: Bool
    
    enum CodingKeys: String, CodingKey {
        case createDiscussionTopic = "create_discussion_topic"
        case createAnnouncement = "create_announcement"
    }
}

struct CalendarLink: Codable, Equatable, Hashable {
    let ics: String
}


extension Course {
    init?(from data: Data) {
        do {
            self = try JSONDecoder().decode(Course.self, from: data)
            
        } catch {
            print("Error decoding course from data: \(error)")
            return nil
        }
        
    }
    
    
}
