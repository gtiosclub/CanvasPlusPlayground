//
//  CourseGradeManager.swift
//  CanvasPlusPlayground
//
//  Created by Songyuan Liu on 9/16/24.
//

import Foundation

@Observable
class CourseGradeManager {
    var enrollments = [Enrollment]()

    func fetchEnrollments() async {
        guard let (data, _) = await CanvasService.shared.fetch(.getEnrollments) else {
            print("Failed to fetch enrollments")
            return
        }
        
        do {
            enrollments = try JSONDecoder().decode([Enrollment].self, from: data)
        } catch {
            print(error)
        }
    }



}
