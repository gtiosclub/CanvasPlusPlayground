//
//  CanvasRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/14/24.
//

import Foundation

struct CanvasRequest {
    static func getCourses(enrollmentState: String, perPage: Int = 50) -> GetCoursesRequest {
        GetCoursesRequest(enrollmentState: enrollmentState, perPage: perPage)
    }

    static func getCourse(id: String) -> GetCourseRequest {
        GetCourseRequest(courseId: id)
    }

    static func getCourseRootFolder(courseId: String) -> GetCourseRootFolderRequest {
        GetCourseRootFolderRequest(courseId: courseId)
    }

    static func getFile(fileId: String) -> GetFileRequest {
        GetFileRequest(fileId: fileId)
    }

    static func getFilesInFolder(folderId: String) -> GetFilesInFolderRequest {
        GetFilesInFolderRequest(folderId: folderId)
    }

    static func getFoldersInFolder(folderId: String) -> GetFoldersInFolderRequest {
        GetFoldersInFolderRequest(folderId: folderId)
    }

    static func getTabs(courseId: String) -> GetTabsRequest {
        GetTabsRequest(courseId: courseId)
    }

    /// Fetches Announcements for one course
    static func getAnnouncements(
        courseId: String,
        startDate: Date = .distantPast,
        endDate: Date = .now,
        perPage: Int = 15
    ) -> GetAnnouncementsRequest {
        GetAnnouncementsRequest(
            courseId: courseId,
            startDate: startDate,
            endDate: endDate,
            perPage: perPage
        )
    }

    /// Fetches announcements for all courses with id's in `courseIds`
    static func getAnnouncements(
        courseIds: [String],
        startDate: Date = .distantPast,
        endDate: Date = .now,
        perPage: Int = 15
    ) -> GetAnnouncementsBatchRequest {
        GetAnnouncementsBatchRequest(
            courseIds: courseIds,
            startDate: startDate,
            endDate: endDate,
            perPage: perPage
        )
    }

    static func getAssignment(id: String, courseId: String) -> GetAssignmentRequest {
        GetAssignmentRequest(assignmentId: id, courseId: courseId)
    }

    static func getAssignments(courseId: String) -> GetAssignmentsRequest {
        GetAssignmentsRequest(courseId: courseId)
    }

    static func getEnrollments(courseId: String, userId: String? = nil, perPage: Int = 50) -> GetEnrollmentsRequest {
        GetEnrollmentsRequest(courseId: courseId, userId: userId, perPage: perPage)
    }

    static func getUsers(
        courseId: String,
        include: [GetCourseUsersRequest.Include] = [],
        searchTerm: String? = nil,
        sort: GetCourseUsersRequest.Sorter? = nil,
        enrollmentType: [EnrollmentType] = [],
        userId: String? = nil,
        userIds: [String] = [],
        enrollmentState: [GetCourseUsersRequest.EnrollmentState] = [],
        perPage: Int = 50
    ) -> GetCourseUsersRequest {
        GetCourseUsersRequest(
            courseId: courseId,
            include: include,
            searchTerm: searchTerm,
            sort: sort,
            enrollmentType: enrollmentType,
            userId: userId,
            userIds: userIds,
            enrollmentState: enrollmentState,
            perPage: perPage
        )
    }

    static func getQuizzes(courseId: String, searchTerm: String? = nil) -> GetQuizzesRequest {
        GetQuizzesRequest(courseId: courseId, searchTerm: searchTerm)
    }

    static func getUser(id: String? = nil) -> GetUserRequest {
        GetUserRequest(userId: id)
    }

    static func getUserProfile(userId: String? = nil) -> GetUserProfileRequest {
        GetUserProfileRequest(userId: userId)
    }

    static func getModules(
        courseId: String,
        searchTerm: String? = nil,
        include: [GetModulesRequest.Include] = [],
        perPage: Int = 25
    ) -> GetModulesRequest {
        GetModulesRequest(
            courseId: courseId,
            searchTerm: searchTerm,
            include: include,
            perPage: perPage
        )
    }

    static func getModuleItems(
        courseId: String,
        moduleId: String,
        searchTerm: String? = nil,
        include: [GetModuleItemsRequest.Include] = [],
        perPage: Int = 25
    ) -> GetModuleItemsRequest {
        GetModuleItemsRequest(
            courseId: courseId,
            moduleId: moduleId,
            include: include,
            searchTerm: searchTerm,
            perPage: perPage
        )
    }

    static func getDiscussionTopics(
        courseId: String,
        include: [GetDiscussionTopicsRequest.Include] = [],
        orderBy: GetDiscussionTopicsRequest.Order? = .position,
        scope: GetDiscussionTopicsRequest.Scope? = nil,
        onlyAnnouncements: Bool = false,
        filterBy: GetDiscussionTopicsRequest.Filter? = .all,
        searchTerm: String? = nil,
        excludeContentModuleLockedTopics: Bool = false,
        perPage: Int = 25
    ) -> GetDiscussionTopicsRequest {
        GetDiscussionTopicsRequest(
            courseId: courseId,
            include: include,
            orderBy: orderBy,
            scope: scope,
            onlyAnnouncements: onlyAnnouncements,
            filterBy: filterBy,
            searchTerm: searchTerm,
            excludeContentModuleLockedTopics: excludeContentModuleLockedTopics,
            perPage: perPage
        )
    }

    static func markCourseDiscussionTopicAsRead(
        courseId: String,
        discussionTopicId: String
    ) -> MarkCourseDiscussionTopicReadRequest {
        MarkCourseDiscussionTopicReadRequest(courseID: courseId, discussionID: discussionTopicId)
    }

    static func markCourseDiscussionTopicAsUnread(
        courseId: String,
        discussionTopicId: String
    ) -> MarkCourseDiscussionTopicUnreadRequest {
        MarkCourseDiscussionTopicUnreadRequest(courseID: courseId, discussionID: discussionTopicId)
    }
}
