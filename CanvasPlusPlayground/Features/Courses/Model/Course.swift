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
    typealias ID = String
    typealias ServerID = Int
    
    // MARK: IDs
    @Attribute(.unique) let id: String
    var parentId: String
    
    // MARK: Other
    var accessRestrictedByDate: Bool
    var bannerImageDownloadURL: URL?
    var canCreateAnnouncement: Bool
    var canCreateDiscussionTopic: Bool
    var courseCode: String?
    /** Teacher assigned course color for K5 in hex format. */
    var courseColor: String?
    var defaultViewRaw: String?
    //var grades: [Grade]?
    var gradingPeriods: [APIGradingPeriod]?
    var hideFinalGrades: Bool
    var imageDownloadURL: URL?
    var isCourseDeleted: Bool
    var isFavorite: Bool
    var isHomeroomCourse: Bool
    /** Use with caution! This property doesn't take section dates or the actual enrollment's concluded state into account. */
    var isPastEnrollment: Bool
    var isPublished: Bool
    var name: String?
    var sections: [APICourseSection]
    var syllabusBody: String?
    var termName: String?
    var settings: APICourseSettings?
    //var gradingSchemeRaw: []?
    //var roles: String? (see enrollmentRolesRaw)
    
    // MARK: Enrollment info
    var enrollments: [EnrollmentAPI]
    var enrollmentTypesRaw: String
    var enrollmentRolesRaw: String
    var enrollmentRoleIds: String
    var enrollmentUserIds: String
    var enrollmentStatesRaw: String

    // MARK: Custom Properties
    // We cannot use `Color` directly because it needs to conform to `PersistentModel`
    var rgbColors: RGBColors?
    //var isFavorite: Bool?
    var nickname: String?
    
    
    var displayName: String {
        nickname ?? name ?? "Unknown Name"
    }
    
    init(_ courseAPI: CourseAPI) {
        
        self.id =  String(describing: courseAPI.id)
        self.parentId = ""
        
        self.name = name
        self.isFavorite = courseAPI.is_favorite ?? false
        self.courseCode = courseAPI.course_code
        self.courseColor = courseAPI.course_color
        self.bannerImageDownloadURL = URL(string: courseAPI.banner_image_download_url ?? "")
        self.imageDownloadURL = URL(string: courseAPI.image_download_url ?? "")
        self.syllabusBody = courseAPI.syllabus_body
        self.defaultViewRaw = courseAPI.default_view?.rawValue
        
        self.gradingPeriods = courseAPI.grading_periods
//        if let apiGradingPeriods = item.grading_periods {
//            let gradingPeriods: [GradingPeriod] = apiGradingPeriods.map { apiGradingPeriod in
//                let gp: GradingPeriod = GradingPeriod.save(apiGradingPeriod, courseID: model.id, in: context)
//                return gp
//            }
//            model.gradingPeriods = Set(gradingPeriods)
//        }
        
        self.hideFinalGrades = courseAPI.hide_final_grades ?? false
        self.isCourseDeleted = courseAPI.workflow_state == .deleted
        self.isPastEnrollment = (
            courseAPI.workflow_state == .completed ||
            (courseAPI.end_at ?? .distantFuture) < .now ||
            (courseAPI.term?.end_at ?? .distantFuture) < .now
        )
        self.isHomeroomCourse = courseAPI.homeroom_course ?? false
        self.isPublished = courseAPI.workflow_state == .available || courseAPI.workflow_state == .completed
        self.termName = courseAPI.term?.name
        self.accessRestrictedByDate = courseAPI.access_restricted_by_date ?? false
        
        // Extra enrollments setup
        self.enrollments = enrollments
        
//        if let contextColor: ContextColor = context.fetch(scope: .where(#keyPath(ContextColor.canvasContextID), equals: model.canvasContextID)).first {
//            model.contextColor = contextColor
//        }
    
        if let permissions = courseAPI.permissions {
            self.canCreateAnnouncement = permissions.create_announcement
            self.canCreateDiscussionTopic = permissions.create_discussion_topic
        }
        
        if let sections = courseAPI.sections {
            self.sections = sections.map {
                APICourseSection.create(from: $0, courseID: courseAPI.id)
            }
        }
        
//        if let dashboardCard: DashboardCard = context.fetch(scope: .where(#keyPath(DashboardCard.id), equals: model.id)).first {
//            dashboardCard.course = model
//        }
        
//        for group: Group in context.fetch(scope: .where(#keyPath(Group.courseID), equals: model.id)) {
//            group.course = model
//        }
        
        self.settings = courseAPI.settings
//        if let apiSettings = item.settings {
//            CourseSettings.save(apiSettings, courseID: item.id.value, in: context)
//        } else if let settings: CourseSettings = context.fetch(scope: .where(#keyPath(CourseSettings.courseID), equals: model.id)).first {
//            model.settings = settings
//        }
//        self.gradingSchemeRaw
        
        //self.roles = courseAPI.enrollments.map(\.role)
        
        self.enrollmentTypesRaw = enrollments.compactMap(\.type).joined(separator: ",")
        self.enrollmentRolesRaw = enrollments.compactMap(\.role).joined(separator: ",")
        self.enrollmentRoleIds = enrollments.compactMap(\.roleID?.asString).joined(separator: ",")
        self.enrollmentStatesRaw = enrollments.compactMap(\.enrollmentState).joined(separator: ",")
        self.enrollmentUserIds = enrollments.compactMap(\.userID.asString).joined(separator: ",")
        
    }
        
    func merge(with other: Course) {
        self.accessRestrictedByDate = other.accessRestrictedByDate
        self.bannerImageDownloadURL = other.bannerImageDownloadURL
        self.canCreateAnnouncement = other.canCreateAnnouncement
        self.canCreateDiscussionTopic = other.canCreateDiscussionTopic
        self.courseCode = other.courseCode
        self.courseColor = other.courseColor
        self.defaultViewRaw = other.defaultViewRaw
        self.gradingPeriods = other.gradingPeriods
        self.hideFinalGrades = other.hideFinalGrades
        self.imageDownloadURL = other.imageDownloadURL
        self.isCourseDeleted = other.isCourseDeleted
        self.isFavorite = other.isFavorite
        self.isHomeroomCourse = other.isHomeroomCourse
        self.isPastEnrollment = other.isPastEnrollment
        self.isPublished = other.isPublished
        self.name = other.name
        self.sections = other.sections
        self.syllabusBody = other.syllabusBody
        self.termName = other.termName
        self.settings = other.settings
        self.enrollments = other.enrollments
        self.enrollmentTypesRaw = other.enrollmentTypesRaw
        self.enrollmentRolesRaw = other.enrollmentRolesRaw
        self.enrollmentRoleIds = other.enrollmentRoleIds
        self.enrollmentUserIds = other.enrollmentUserIds
        self.enrollmentStatesRaw = other.enrollmentStatesRaw
        
        self.rgbColors = other.rgbColors
        self.nickname = other.nickname
    }
}

