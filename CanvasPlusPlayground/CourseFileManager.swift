//
//  CourseFileManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/8/24.
//

import SwiftUI

@Observable
class CourseFileManager {
    private let courseID: String?
    var files = [File]()

    init(courseID: String?) {
        self.courseID = courseID
    }

    func fetchFiles() async {
        guard let courseID, let (data, _) = try? await CanvasService.shared.fetchResponse(.getAllCourseFiles(courseId: courseID)) else {
            print("Failed to fetch files.")
            return
        }
        
        do {
            self.files = try JSONDecoder().decode([File].self, from: data)
        } catch {
            print(error)
        }
    }
}
