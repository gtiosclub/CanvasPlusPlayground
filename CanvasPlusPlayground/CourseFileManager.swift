//
//  CourseFileManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/8/24.
//

import SwiftUI

@Observable
class CourseFileManager {
    private let courseID: Int?
    var files = [File]()

    init(courseID: Int?) {
        self.courseID = courseID
    }

    func fetchFiles() async {
        guard let courseID, let (data, response) = await CanvasService.fetch(.getCourseFiles(courseId: courseID)) else {
            print("Failed to fetch files.")
            return
        }
        
        if let retFiles = try? JSONDecoder().decode([File].self, from: data) {
            self.files = retFiles
        } else {
            print("Failed to decode file data.")
        }
    }
}
