//
//  Course.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

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
    // var contextColor: ContextColor?
    var courseCode: String?
    /** Teacher assigned course color for K5 in hex format. */
    var courseColor: String?
    var defaultViewRaw: String?
    var calendarIcs: String?

    // MARK: Enrollment info
    var enrollments: [CourseAPI.Enrollment]
    var enrollmentTypesRaw: String
    var enrollmentRolesRaw: String // (var roles)
    var enrollmentRoleIds: String
    var enrollmentUserIds: String
    var enrollmentStatesRaw: String

    // var grades: [Grade]?
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
    var gradingScheme: [APIGradingSchemeEntry]
    // var roles: String? (see enrollmentRolesRaw)
    var tabs: [TabAPI]

    var defaultView: CourseDefaultView? {
        get { return CourseDefaultView(rawValue: defaultViewRaw ?? "") }
        set { defaultViewRaw = newValue?.rawValue }
    }

    // MARK: Custom Properties
    // We cannot use `Color` directly because it needs to conform to `PersistentModel`
    var rgbColors: RGBColors?
    // var isFavorite: Bool?
    var nickname: String?

    var displayName: String {
        nickname ?? name ?? "Unknown Name"
    }

    init(_ courseAPI: CourseAPI) {

        self.id =  String(describing: courseAPI.id)
        self.parentId = ""

        self.name = courseAPI.name
        self.isFavorite = courseAPI.is_favorite ?? false
        self.courseCode = courseAPI.course_code
        self.courseColor = courseAPI.course_color
        self.bannerImageDownloadURL = URL(string: courseAPI.banner_image_download_url ?? "")
        self.imageDownloadURL = URL(string: courseAPI.image_download_url ?? "")
        self.syllabusBody = courseAPI.syllabus_body
        self.defaultViewRaw = courseAPI.default_view?.rawValue
//        self.enrollments.forEach {
//            if $0.id == nil {
//              CanvasService.shared.repository?.delete()
//            }
//        }

        self.calendarIcs = courseAPI.calendar?.ics

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
        let enrollments = courseAPI.enrollments ?? []
        self.enrollments = enrollments
        self.enrollmentTypesRaw = enrollments.compactMap(\.type).joined(separator: ",")
        self.enrollmentRolesRaw = enrollments.compactMap(\.role).joined(separator: ",")
        self.enrollmentRoleIds = enrollments.compactMap(\.role_id?.asString).joined(separator: ",")
        self.enrollmentStatesRaw = enrollments.compactMap(\.enrollment_state?.rawValue).joined(separator: ",")
        self.enrollmentUserIds = enrollments.compactMap(\.user_id?.asString).joined(separator: ",")
//        if let apiEnrollments = item.enrollments {
//            let enrollmentModels: [Enrollment] = apiEnrollments.map { apiItem in
//                /// This enrollment contains the grade fields necessary to calculate grades on the dashboard.
//                /// This is a special enrollment that has no courseID nor enrollmentID and contains no Grade objects.
//                let e: Enrollment = context.insert()
//                e.update(fromApiModel: apiItem, course: model, in: context)
//                return e
//            }
//            model.enrollments = Set(enrollmentModels)
//        }

//        if let contextColor: ContextColor = context.fetch(
//            scope: .where(
//                #keyPath(ContextColor.canvasContextID),
//                equals: model.canvasContextID
//            )
//        ).first {
//            model.contextColor = contextColor
//        }

        self.canCreateAnnouncement = false
        self.canCreateDiscussionTopic = false
        if let permissions = courseAPI.permissions {
            self.canCreateAnnouncement = permissions.create_announcement
            self.canCreateDiscussionTopic = permissions.create_discussion_topic
        }

        self.sections = []
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

        self.gradingScheme = courseAPI.grading_scheme?.compactMap {
            APIGradingSchemeEntry(courseGradingScheme: $0)
        } ?? []

//        model.roles = item.enrollments.roles

        self.tabs = courseAPI.tabs ?? []
//        if let apiTabs = item.tabs {
//            let courseContext = Context.course(item.id.value)
//
//            let contextPredicate = NSPredicate(
//                format: "%K == %@", #keyPath(Tab.contextRaw),
//                courseContext.canvasContextID
//            )
//
//            context.delete(context.fetch(contextPredicate) as [Tab])
//
//            // not adding tabs to Course, just saving them
//            apiTabs.forEach { apiTab in
//                let tab: Tab = context.insert()
//                tab.save(apiTab, in: context, context: courseContext)
//            }
//        }
//
//        
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

        // Note: These must NOT be merged.
//        self.isFavorite = other.isFavorite
//        self.rgbColors = other.rgbColors
//        self.nickname = other.nickname
    }
}
