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
    
    static func getFilesInFolder(folderId: String) -> GetFilesInFolderRequest {
        GetFilesInFolderRequest(folderId: folderId)
    }
    
    static func getFoldersInFolder(folderId: String) -> GetFoldersInFolderRequest {
        GetFoldersInFolderRequest(folderId: folderId)
    }
    
    static func getTabs(courseId: String) -> GetTabsRequest {
        GetTabsRequest(courseId: courseId)
    }
    
    static func getAnnouncements(courseId: String, startDate: Date = .distantPast, endDate: Date = .now, perPage: Int = 15) -> GetAnnouncementsRequest {
        GetAnnouncementsRequest(courseId: courseId, startDate: startDate, endDate: endDate, perPage: perPage)
    }
    
    static func getAssignments(courseId: String) -> GetAssignmentsRequest {
        GetAssignmentsRequest(courseId: courseId)
    }
    
    static func getEnrollments(courseId: String, perPage: Int = 50) -> GetEnrollmentsRequest {
        GetEnrollmentsRequest(courseId: courseId, perPage: perPage)
    }
    
    static func getQuizzes(courseId: String, searchTerm: String? = nil) -> GetQuizzesRequest {
        GetQuizzesRequest(courseId: courseId, searchTerm: searchTerm)
    }
}
