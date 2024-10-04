//
//  CourseGradeView.swift
//  CanvasPlusPlayground
//
//  Created by Songyuan Liu on 9/16/24.
//

import SwiftUI

struct CourseGradeView: View {
    @Environment(CourseManager.self) var courseManager
    @State private var enrollment: Enrollment?
    
    let course: Course
    
    
    init(course: Course) {
        self.course = course
    }
    
    var body: some View {
        List {
            display("Current Score", value: enrollment?.grades?.currentScore)
            display("Current grade", value: enrollment?.grades?.currentGrade)
            display("Final Score", value: enrollment?.grades?.finalScore)
            display("Final Grade", value: enrollment?.grades?.finalGrade)
        }
        .onAppear {
            for enroll in courseManager.enrollments {
                if let idLHS = self.course.id, let idRHS = enroll.courseID, idLHS == idRHS  {
                        self.enrollment = enroll
                }
            }
        }
    }
    
    func display(_ label: String, value: Any?) -> Text {
        if let value = value {
            return Text("\(label): \(value)")
        } else {
            return Text("\(label) unavailable")
        }
    }
}

