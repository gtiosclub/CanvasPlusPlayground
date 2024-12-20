//
//  GetCourseRootFolder.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/20/24.
//

import Foundation

struct GetCourseRootFolderRequest: APIRequest {
    typealias Subject = Folder
    
    let courseId: String
    
    var path: String { "courses/\(courseId)/folders/root" }
    var queryParameters: [QueryParameter] {
        []
    }
    
    // MARK: request Id
    var requestId: String { "\(courseId)_root_folder" }
    var requestIdKey: ParentKeyPath<Folder, String> { .createWritable(\.parentId) }
    var customPredicate: Predicate<Folder> {
        .true
    }
}
