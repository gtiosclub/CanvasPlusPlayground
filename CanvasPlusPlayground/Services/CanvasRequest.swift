//
//  CanvasAPI.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/14/24.
//

import Foundation

enum CanvasRequest {
    static let baseURL = URL(string: "https://gatech.instructure.com/api/v1")
    
    case getCourses(enrollmentState: String, perPage: String = "50")
    case getCourse(id: String)
    
    case getCourseRootFolder(courseId: String)
    case getAllCourseFiles(courseId: String)
    case getAllCourseFolders(courseId: String)
    case getFilesForFolder(folderId: String)
    case getFoldersForFolder(folderId: String)
    
    case getTabs(courseId: String)
    
    case getAnnouncements(courseId: String)
    
    case getAssignments(courseId: String)
    
    case getEnrollments
    case getPeople(courseId: String, perPage: String = "100")
    
    var path: String {
        switch self {
            
        case .getCourses:
            "courses"
        case let .getCourse(id):
            "courses/\(id)"
            
        case let .getCourseRootFolder(courseId):
            "courses/\(courseId)/folders/root"
        case let .getAllCourseFiles(courseId):
            "courses/\(courseId)/files"
        case let .getAllCourseFolders(courseId):
            "courses/\(courseId)/folders"
        case let .getFilesForFolder(folderId):
            "folders/\(folderId)/files"
        case let .getFoldersForFolder(folderId):
            "folders/\(folderId)/folders"
            
        case let .getTabs(courseId):
            "courses/\(courseId)/tabs"
            
        case .getAnnouncements:
            "announcements"
            
        case let .getAssignments(courseId):
            "courses/\(courseId)/assignments"
            
        case .getEnrollments:
            "users/self/enrollments"
        case let .getPeople(courseId, _):
            "courses/\(courseId)/enrollments"
        }
    }
    
    var queryParameters: [(name: String, value: String)] {
        var params = [(name: "access_token", value: StorageKeys.accessTokenValue)]
        
        let additional: [(String, String)] = switch self {
        case let .getCourses(enrollment_state, perPage):
            [
                ("enrollment_state", enrollment_state),
                ("per_page", perPage)
            ]
        case let .getAnnouncements(courseId):
            [
                ("context_codes[]", "course_\(courseId)")
            ]
        case .getEnrollments:
            [
                ("state[]", "active"),
            ]
        case let .getPeople(_, perPage):
            [
                ("per_page", perPage)
            ]
        default:
            []
        }
        
        params.append(contentsOf: additional)
        
        return params
    }
    
    /// The id that most uniquely identifies the request (if any), e.g. getCourses -> nil, getCourse -> courseId, getAnnouncements -> courseId, getAnnouncement -> announcementId
    var id: String? {
        switch self {
        case let .getCourse(id):
            return id
        case let .getTabs(courseId), let .getAnnouncements(courseId), let .getAssignments(courseId), let .getPeople(courseId, _), let.getCourseRootFolder(courseId), let .getAllCourseFiles(courseId),  let .getAllCourseFolders(courseId):
            return courseId
        case let .getFilesForFolder(folderId), let .getFoldersForFolder(folderId):
            return folderId
        default:
            return nil
        }
    }
    
    var yieldsCollection: Bool {
        self.associatedModel is any Collection.Type
    }
    
    var isPaginated: Bool {
        switch self {
        case .getCourses, .getAnnouncements, .getPeople, .getAllCourseFiles, .getAllCourseFolders, .getFilesForFolder, .getFoldersForFolder:
            true
        default:
            false
        }
    }
    
    var associatedModel: Codable.Type {
        return switch self {
        case .getCourses:
            [Course].self
        case .getCourse:
            Course.self
            
        case .getCourseRootFolder:
            Folder.self
        case .getAllCourseFiles:
            [File].self
        case .getAllCourseFolders:
            [Folder].self
        case .getFilesForFolder:
            [File].self
        case .getFoldersForFolder:
            [Folder].self
            
        case .getTabs:
            [Tab].self
        case .getAnnouncements:
            [Announcement].self
        case .getAssignments:
            [Assignment].self
        case .getEnrollments:
            [Enrollment].self
        case .getPeople:
            [User].self
        }
    }
}

extension CanvasRequest {
    var url: URL? {
        Self.baseURL?
            .appendingPathComponent(path)
            .appending(queryItems: queryParameters.map { name, val in
                URLQueryItem(name: name, value: val)
            })
    }
}
