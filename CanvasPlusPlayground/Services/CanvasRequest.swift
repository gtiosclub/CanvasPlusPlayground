//
//  CanvasAPI.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 9/14/24.
//

import Foundation

enum CanvasRequest: Hashable {
    static let baseURL = URL(string: "https://gatech.instructure.com/api/v1")
    
    case getCourses(enrollmentState: String, perPage: String = "50")
    case getCourse(id: String)
    
    case getCourseRootFolder(courseId: String)
    case getAllCourseFiles(courseId: String)
    case getAllCourseFolders(courseId: String)
    case getFilesInFolder(folderId: String)
    case getFoldersInFolder(folderId: String)
    
    case getTabs(courseId: String)

    case getAnnouncements(courseId: String, startDate: Date = .distantPast, endDate: Date = .now, perPage: String = "100")
  
    case getAssignments(courseId: String)
    
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
        case let .getFilesInFolder(folderId):
            "folders/\(folderId)/files"
        case let .getFoldersInFolder(folderId):
            "folders/\(folderId)/folders"
            
        case let .getTabs(courseId):
            "courses/\(courseId)/tabs"
            
        case .getAnnouncements:
            "announcements"
            
        case let .getAssignments(courseId):
            "courses/\(courseId)/assignments"
            
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
        case let .getAnnouncements(courseId, startDate, endDate, perPage):
            [
                ("context_codes[]", "course_\(courseId)"),
                ("start_date", startDate.ISO8601Format()),
                ("end_date", endDate.ISO8601Format()),
                ("per_page", perPage)
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
    var id: String {
        switch self {
        case let .getCourse(id):
            return id
        case let .getTabs(courseId), let .getAnnouncements(courseId, _, _, _), let .getAssignments(courseId), let .getPeople(courseId, _), let .getAllCourseFiles(courseId),  let .getAllCourseFolders(courseId):
            return courseId
        case let.getCourseRootFolder(courseId):
            return "\(courseId)_root"
        case let .getFilesInFolder(folderId), let .getFoldersInFolder(folderId):
            return folderId
        case .getCourses:
            return "courses_\(StorageKeys.accessTokenValue)" // In case user changes
        }
    }
    
    var yieldsCollection: Bool {
        self.associatedModel is any Collection.Type
    }
    
    var isPaginated: Bool {
        switch self {
        case .getCourses, .getAnnouncements, .getPeople, .getAllCourseFiles, .getAllCourseFolders, .getFilesInFolder, .getFoldersInFolder:
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
        case .getFilesInFolder:
            [File].self
        case .getFoldersInFolder:
            [Folder].self
            
        case .getTabs:
            [Tab].self
        case .getAnnouncements:
            [Announcement].self
        case .getAssignments:
            [Assignment].self
        case .getPeople:
            [Enrollment].self
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
