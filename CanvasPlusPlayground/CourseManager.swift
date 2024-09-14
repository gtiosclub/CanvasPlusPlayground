//
//  CourseManager.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI

@Observable
class CourseManager {
    var courses = [Course]()

    func getCourses() async {
        guard let (data, response) = await CanvasService.fetch(.getCourses(enrollmentState: "active")) else {
            print("Failed to fetch files.")
            return
        }
        
        if let retCourses = try? JSONDecoder().decode([Course].self, from: data) {
            self.courses = retCourses
        } else {
            print("Failed to decode file data.")
        }
    }
}
