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
    case getCourse(id: Int)
    case getCourseFiles(courseId: Int)
    case getTabs(courseId: Int)
    case getAnnouncements(courseId: Int)
    case getAssignments(courseId: Int)
    
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
        case let .getAnnouncements:
            "announcements"
        case let .getAssignments(courseId):
            "courses/\(courseId)/assignments"
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
        default:
            []
        }
        
        params.append(contentsOf: additional)
        
        return params
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