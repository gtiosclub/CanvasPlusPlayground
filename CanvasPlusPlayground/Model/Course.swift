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
final class Course: Cacheable {
    typealias ServerID = Int
    
    @Attribute(.unique) var id: String
    
    /*@Relationship()*/ var enrollments: [Enrollment]?
    
    var sisCourseID: String?
    var uuid: String?
    var integrationID: String?
    var sisImportID: Int?
    var name: String?
    var courseCode: String?
    var originalName: String?
    var workflowState: String?
    var accountID: Int?
    var rootAccountID: Int?
    var enrollmentTermID: Int?
    var gradingPeriods: [String]?
    var gradingStandardID: Int?
    var gradePassbackSetting: String?
    var createdAt: String?
    var startAt: String?
    var endAt: String?
    var locale: String?
    var totalStudents: Int?
    var calendar: CalendarLink?
    var defaultView: String?
    var syllabusBody: String?
    var needsGradingCount: Int?
    var term: String?
    var courseProgress: String?
    var applyAssignmentGroupWeights: Bool?
    var permissions: Permissions?
    var isPublic: Bool?
    var isPublicToAuthUsers: Bool?
    var publicSyllabus: Bool?
    var publicSyllabusToAuth: Bool?
    var publicDescription: String?
    var storageQuotaMB: Int?
    var storageQuotaUsedMB: Int?
    var hideFinalGrades: Bool?
    var license: String?
    var allowStudentAssignmentEdits: Bool?
    var allowWikiComments: Bool?
    var allowStudentForumAttachments: Bool?
    var openEnrollment: Bool?
    var selfEnrollment: Bool?
    var restrictEnrollmentsToCourseDates: Bool?
    var courseFormat: String?
    var accessRestrictedByDate: Bool?
    var timeZone: String?
    var blueprint: Bool?
    var blueprintRestrictions: [String: Bool]?
    var blueprintRestrictionsByObjectType: [String: [String: Bool]]?
    var template: Bool?

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
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let id = try container.decode(ServerID.self, forKey: .id)
        self.id =  String(describing: id)
        
        self.sisCourseID = try container.decodeIfPresent(String.self, forKey: .sisCourseID)
        self.uuid = try container.decodeIfPresent(String.self, forKey: .uuid)
        self.integrationID = try container.decodeIfPresent(String.self, forKey: .integrationID)
        self.sisImportID = try container.decodeIfPresent(Int.self, forKey: .sisImportID)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.courseCode = try container.decodeIfPresent(String.self, forKey: .courseCode)
        self.originalName = try container.decodeIfPresent(String.self, forKey: .originalName)
        self.workflowState = try container.decodeIfPresent(String.self, forKey: .workflowState)
        self.accountID = try container.decodeIfPresent(Int.self, forKey: .accountID)
        self.rootAccountID = try container.decodeIfPresent(Int.self, forKey: .rootAccountID)
        self.enrollmentTermID = try container.decodeIfPresent(Int.self, forKey: .enrollmentTermID)
        self.gradingPeriods = try container.decodeIfPresent([String].self, forKey: .gradingPeriods)
        self.gradingStandardID = try container.decodeIfPresent(Int.self, forKey: .gradingStandardID)
        self.gradePassbackSetting = try container.decodeIfPresent(String.self, forKey: .gradePassbackSetting)
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        self.startAt = try container.decodeIfPresent(String.self, forKey: .startAt)
        self.endAt = try container.decodeIfPresent(String.self, forKey: .endAt)
        self.locale = try container.decodeIfPresent(String.self, forKey: .locale)
        self.enrollments = try container.decodeIfPresent([Enrollment].self, forKey: .enrollments)
        self.totalStudents = try container.decodeIfPresent(Int.self, forKey: .totalStudents)
        self.calendar = try container.decodeIfPresent(CalendarLink.self, forKey: .calendar)
        self.defaultView = try container.decodeIfPresent(String.self, forKey: .defaultView)
        self.syllabusBody = try container.decodeIfPresent(String.self, forKey: .syllabusBody)
        self.needsGradingCount = try container.decodeIfPresent(Int.self, forKey: .needsGradingCount)
        self.term = try container.decodeIfPresent(String.self, forKey: .term)
        self.courseProgress = try container.decodeIfPresent(String.self, forKey: .courseProgress)
        self.applyAssignmentGroupWeights = try container.decodeIfPresent(Bool.self, forKey: .applyAssignmentGroupWeights)
        self.permissions = try container.decodeIfPresent(Permissions.self, forKey: .permissions)
        self.isPublic = try container.decodeIfPresent(Bool.self, forKey: .isPublic)
        self.isPublicToAuthUsers = try container.decodeIfPresent(Bool.self, forKey: .isPublicToAuthUsers)
        self.publicSyllabus = try container.decodeIfPresent(Bool.self, forKey: .publicSyllabus)
        self.publicSyllabusToAuth = try container.decodeIfPresent(Bool.self, forKey: .publicSyllabusToAuth)
        self.publicDescription = try container.decodeIfPresent(String.self, forKey: .publicDescription)
        self.storageQuotaMB = try container.decodeIfPresent(Int.self, forKey: .storageQuotaMB)
        self.storageQuotaUsedMB = try container.decodeIfPresent(Int.self, forKey: .storageQuotaUsedMB)
        self.hideFinalGrades = try container.decodeIfPresent(Bool.self, forKey: .hideFinalGrades)
        self.license = try container.decodeIfPresent(String.self, forKey: .license)
        self.allowStudentAssignmentEdits = try container.decodeIfPresent(Bool.self, forKey: .allowStudentAssignmentEdits)
        self.allowWikiComments = try container.decodeIfPresent(Bool.self, forKey: .allowWikiComments)
        self.allowStudentForumAttachments = try container.decodeIfPresent(Bool.self, forKey: .allowStudentForumAttachments)
        self.openEnrollment = try container.decodeIfPresent(Bool.self, forKey: .openEnrollment)
        self.selfEnrollment = try container.decodeIfPresent(Bool.self, forKey: .selfEnrollment)
        self.restrictEnrollmentsToCourseDates = try container.decodeIfPresent(Bool.self, forKey: .restrictEnrollmentsToCourseDates)
        self.courseFormat = try container.decodeIfPresent(String.self, forKey: .courseFormat)
        self.accessRestrictedByDate = try container.decodeIfPresent(Bool.self, forKey: .accessRestrictedByDate)
        self.timeZone = try container.decodeIfPresent(String.self, forKey: .timeZone)
        self.blueprint = try container.decodeIfPresent(Bool.self, forKey: .blueprint)
        self.blueprintRestrictions = try container.decodeIfPresent([String: Bool].self, forKey: .blueprintRestrictions)
        self.blueprintRestrictionsByObjectType = try container.decodeIfPresent([String: [String: Bool]].self, forKey: .blueprintRestrictionsByObjectType)
        self.template = try container.decodeIfPresent(Bool.self, forKey: .template)
    }
    
    func encode(to encoder: Encoder) throws {
       var container = encoder.container(keyedBy: CodingKeys.self)
       try container.encode(id, forKey: .id)
       try container.encodeIfPresent(sisCourseID, forKey: .sisCourseID)
       try container.encodeIfPresent(uuid, forKey: .uuid)
       try container.encodeIfPresent(integrationID, forKey: .integrationID)
       try container.encodeIfPresent(sisImportID, forKey: .sisImportID)
       try container.encodeIfPresent(name, forKey: .name)
       try container.encodeIfPresent(courseCode, forKey: .courseCode)
       try container.encodeIfPresent(originalName, forKey: .originalName)
       try container.encodeIfPresent(workflowState, forKey: .workflowState)
       try container.encodeIfPresent(accountID, forKey: .accountID)
       try container.encodeIfPresent(rootAccountID, forKey: .rootAccountID)
       try container.encodeIfPresent(enrollmentTermID, forKey: .enrollmentTermID)
       try container.encodeIfPresent(gradingPeriods, forKey: .gradingPeriods)
       try container.encodeIfPresent(gradingStandardID, forKey: .gradingStandardID)
       try container.encodeIfPresent(gradePassbackSetting, forKey: .gradePassbackSetting)
       try container.encodeIfPresent(createdAt, forKey: .createdAt)
       try container.encodeIfPresent(startAt, forKey: .startAt)
       try container.encodeIfPresent(endAt, forKey: .endAt)
       try container.encodeIfPresent(locale, forKey: .locale)
       try container.encodeIfPresent(enrollments, forKey: .enrollments)
       try container.encodeIfPresent(totalStudents, forKey: .totalStudents)
       try container.encodeIfPresent(calendar, forKey: .calendar)
       try container.encodeIfPresent(defaultView, forKey: .defaultView)
       try container.encodeIfPresent(syllabusBody, forKey: .syllabusBody)
       try container.encodeIfPresent(needsGradingCount, forKey: .needsGradingCount)
       try container.encodeIfPresent(term, forKey: .term)
       try container.encodeIfPresent(courseProgress, forKey: .courseProgress)
       try container.encodeIfPresent(applyAssignmentGroupWeights, forKey: .applyAssignmentGroupWeights)
       try container.encodeIfPresent(permissions, forKey: .permissions)
       try container.encodeIfPresent(isPublic, forKey: .isPublic)
       try container.encodeIfPresent(isPublicToAuthUsers, forKey: .isPublicToAuthUsers)
       try container.encodeIfPresent(publicSyllabus, forKey: .publicSyllabus)
       try container.encodeIfPresent(publicSyllabusToAuth, forKey: .publicSyllabusToAuth)
       try container.encodeIfPresent(publicDescription, forKey: .publicDescription)
       try container.encodeIfPresent(storageQuotaMB, forKey: .storageQuotaMB)
       try container.encodeIfPresent(storageQuotaUsedMB, forKey: .storageQuotaUsedMB)
       try container.encodeIfPresent(hideFinalGrades, forKey: .hideFinalGrades)
       try container.encodeIfPresent(license, forKey: .license)
       try container.encodeIfPresent(allowStudentAssignmentEdits, forKey: .allowStudentAssignmentEdits)
       try container.encodeIfPresent(allowWikiComments, forKey: .allowWikiComments)
       try container.encodeIfPresent(allowStudentForumAttachments, forKey: .allowStudentForumAttachments)
       try container.encodeIfPresent(openEnrollment, forKey: .openEnrollment)
       try container.encodeIfPresent(selfEnrollment, forKey: .selfEnrollment)
       try container.encodeIfPresent(restrictEnrollmentsToCourseDates, forKey: .restrictEnrollmentsToCourseDates)
       try container.encodeIfPresent(courseFormat, forKey: .courseFormat)
       try container.encodeIfPresent(accessRestrictedByDate, forKey: .accessRestrictedByDate)
       try container.encodeIfPresent(timeZone, forKey: .timeZone)
       try container.encodeIfPresent(blueprint, forKey: .blueprint)
       try container.encodeIfPresent(blueprintRestrictions, forKey: .blueprintRestrictions)
       try container.encodeIfPresent(blueprintRestrictionsByObjectType, forKey: .blueprintRestrictionsByObjectType)
       try container.encodeIfPresent(template, forKey: .template)
   }
    
    func merge(with other: Course) {
        self.id = other.id
        self.sisCourseID = other.sisCourseID
        self.uuid = other.uuid
        self.integrationID = other.integrationID
        self.sisImportID = other.sisImportID
        self.name = other.name
        self.courseCode = other.courseCode
        self.originalName = other.originalName
        self.workflowState = other.workflowState
        self.accountID = other.accountID
        self.rootAccountID = other.rootAccountID
        self.enrollmentTermID = other.enrollmentTermID
        self.gradingPeriods = other.gradingPeriods
        self.gradingStandardID = other.gradingStandardID
        self.gradePassbackSetting = other.gradePassbackSetting
        self.createdAt = other.createdAt
        self.startAt = other.startAt
        self.endAt = other.endAt
        self.locale = other.locale
        self.enrollments = other.enrollments
        self.totalStudents = other.totalStudents
        self.calendar = other.calendar
        self.defaultView = other.defaultView
        self.syllabusBody = other.syllabusBody
        self.needsGradingCount = other.needsGradingCount
        self.term = other.term
        self.courseProgress = other.courseProgress
        self.applyAssignmentGroupWeights = other.applyAssignmentGroupWeights
        self.permissions = other.permissions
        self.isPublic = other.isPublic
        self.isPublicToAuthUsers = other.isPublicToAuthUsers
        self.publicSyllabus = other.publicSyllabus
        self.publicSyllabusToAuth = other.publicSyllabusToAuth
        self.publicDescription = other.publicDescription
        self.storageQuotaMB = other.storageQuotaMB
        self.storageQuotaUsedMB = other.storageQuotaUsedMB
        self.hideFinalGrades = other.hideFinalGrades
        self.license = other.license
        self.allowStudentAssignmentEdits = other.allowStudentAssignmentEdits
        self.allowWikiComments = other.allowWikiComments
        self.allowStudentForumAttachments = other.allowStudentForumAttachments
        self.openEnrollment = other.openEnrollment
        self.selfEnrollment = other.selfEnrollment
        self.restrictEnrollmentsToCourseDates = other.restrictEnrollmentsToCourseDates
        self.courseFormat = other.courseFormat
        self.accessRestrictedByDate = other.accessRestrictedByDate
        self.timeZone = other.timeZone
        self.blueprint = other.blueprint
        self.blueprintRestrictions = other.blueprintRestrictions
        self.blueprintRestrictionsByObjectType = other.blueprintRestrictionsByObjectType
        self.template = other.template
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

extension String {
    var asInt: Int {
        Int(self) ?? 0
    }
}
