//
//  APIRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/17/24.
//

import Foundation

protocol APIRequest {
    associatedtype Subject: Codable
    associatedtype QueryResult = Subject
    
    typealias QueryParameter = (name: String, value: String?)
    
    var path: String { get }
    var queryParameters: [QueryParameter] { get }
    
    var requestId: String? { get }
    var requestIdKey: KeyPath<Subject, String>? { get }
}

extension APIRequest {
    var baseURL: URL {
        URL(string: "https://gatech.instructure.com/api/v1")!
    }
    
    var combinedQueryParams: [QueryParameter] {
        ([(name: "access_token", value: StorageKeys.accessTokenValue)] + queryParameters).compactMap {
            let (key, val) = $0
            if val == nil {
                return nil
            } else { return $0 }
        }
    }
    
    var url: URL {
        baseURL
            .appendingPathComponent(path)
            .appending(queryItems: combinedQueryParams.map { name, val in
                URLQueryItem(name: name, value: val)
            })
    }
}

extension APIRequest {
    var yieldsCollection: Bool {
        QueryResult.self is any Collection.Type
    }
}

protocol ArrayAPIRequest: APIRequest {
    associatedtype QueryResult = [Subject]
}

struct GetCoursesRequest: ArrayAPIRequest {
    typealias Subject = Course
    
    var path: String { "courses" }
    var queryParameters: [QueryParameter] {
        [
            ("enrollment_state", enrollmentState),
            ("per_page", perPage)
        ]
    }
    
    // MARK: Query Params
    let enrollmentType: String? = "enrolled"
    let enrollmentState: String? = "active"
    let perPage: String? = "50"
    
    // MARK:
    var requestId: String? { "courses_\(StorageKeys.accessTokenValue)" }
    var requestIdKey: KeyPath<Course, String>? { \.parentId }
}


struct GetCourseRequest: APIRequest {
    typealias Subject = Course
    
    let courseId: String
    
    var path: String { "courses/\(courseId)" }
    var queryParameters: [QueryParameter] {
        []
    }
    
    var requestId: String? { courseId }
    var requestIdKey: KeyPath<Course, String>? { \.id }
}
