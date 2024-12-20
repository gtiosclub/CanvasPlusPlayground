//
//  GetCoursesRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/20/24.
//

import Foundation

struct GetCoursesRequest: ArrayAPIRequest {
    typealias Subject = Course
    
    var path: String { "courses" }
    var queryParameters: [QueryParameter] {
        [
            ("enrollment_type", enrollmentType),
            ("enrollment_role", enrollmentRole),
            ("enrollment_role_id", enrollmentRoleId),
            ("enrollment_state", enrollmentState),
            ("exclude_blueprint_courses", excludeBlueprintCourses),
            ("state", state),
            ("per_page", perPage)
        ]
        + include.map { ("include[]", $0) }
        + state.map { ("state[]", $0) }
    }
    
    // MARK: Query Params
    let enrollmentType: String?
    let enrollmentRole: String?
    let enrollmentRoleId: Int?
    let enrollmentState: String?
    let excludeBlueprintCourses: Bool?
    let include: [String]
    let state: [String]
    let perPage: Int

    // MARK: request Id
    var requestId: String { "courses_\(StorageKeys.accessTokenValue)" }
    var requestIdKey: ParentKeyPath<Course, String> { .createWritable(\.parentId) }
    var customPredicate: Predicate<Course> {
        // TODO: match query params
        #Predicate<Course> { course in
            true
        }
    }
}
