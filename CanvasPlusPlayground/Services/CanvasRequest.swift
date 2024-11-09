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
    case getCourseFiles(courseId: String)
    case getTabs(courseId: String)
    case getAnnouncements(courseId: String)
    case getAssignments(courseId: String)
    case getEnrollments
    case getPeople(courseId: String, bookmark: String)
    var path: String {
        switch self {
        case .getCourses:
            "courses"
        case let .getCourse(id):
            "courses/\(id)"
        case let .getCourseFiles(courseId):
            "courses/\(courseId)/files"
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
                ("state[]", "active")
            ]
        case let .getPeople(_, bookmark):
            (!bookmark.isEmpty) ? [("page", bookmark)] : []
        default:
            []
        }
        
        params.append(contentsOf: additional)
        
        return params
    }
    
    var id: String? {
        switch self {
        case .getCourse(let id):
            return id
        default:
            return nil
        }
    }
    
    var yieldsCollection: Bool {
        switch self {
        case .getCourse:
            false
        default:
            true
        }
    }
    
    var associatedModel: Codable.Type {
        return switch self {
        case .getCourses:
            [Course].self
        case .getCourse:
            Course.self
        case .getCourseFiles:
            [File].self
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
