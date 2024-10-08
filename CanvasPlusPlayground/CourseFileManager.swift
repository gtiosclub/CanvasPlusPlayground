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
        guard let courseID, let (data, _) = await CanvasService.shared.fetch(.getCourseFiles(courseId: courseID)) else {
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
