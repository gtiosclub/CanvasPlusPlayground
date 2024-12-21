//
//  GetCourseRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/20/24.
//
import Foundation

struct GetCourseRequest: APIRequest {
    typealias Subject = Course
    
    let courseId: String
    
    var path: String { "courses/\(courseId)" }
    var queryParameters: [QueryParameter] {
        [
            ("teacher_limit", teacherLimit)
        ]
        + include.map { ("include[]", $0) }
    }
    
    let include: [String] = []
    let teacherLimit: Int? = nil
    
    init(courseId: String, include: [String] = [], teacherLimit: Int? = nil) {
        self.courseId = courseId
        self.include = include
        self.teacherLimit = teacherLimit
    }
    
    var requestId: String { courseId }
    var requestIdKey: ParentKeyPath<Course, String> { .createReadable(\.id) }
    var customPredicate: Predicate<Course> {
        .true
    }
}
