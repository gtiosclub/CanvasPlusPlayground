//
//  CourseGradeView.swift
//  CanvasPlusPlayground
//
//  Created by Songyuan Liu on 9/16/24.
//

import SwiftUI

struct CourseGradeView: View {
    let course: Course
    @State private var enrollment: Enrollment?
    @State private var gradeManager: CourseGradeManager
    
    init(course: Course) {
        self.course = course
        _gradeManager = .init(initialValue: CourseGradeManager())
    }
    
    
    var body: some View {
        List {
            if let score = enrollment?.grades?.currentScore {
                Text("Current Score: \(score)")
            } else {
                Text("Current Score unavailable")
            }
            
            if let grade = enrollment?.grades?.currentGrade {
                Text("Current Grade: \(grade)")
            } else {
                Text("Current grade unavailable")
            }
            
            if let finalScore = enrollment?.grades?.finalScore {
                Text("Final Score: \(finalScore)")
            } else {
                Text("Final Score unavailable")
            }
            
            if let finalGrade = enrollment?.grades?.finalGrade {
                Text("Current Score: \(finalGrade)")
            } else {
                Text("Final Grade unavailable")
            }
            
        }
        .task {
            await gradeManager.fetchEnrollments()
            
            for enroll in self.gradeManager.enrollments {
                if let idLHS = enroll.courseID, let idRHS = self.course.id {
                    if idLHS == idRHS {
                        self.enrollment = enroll
                    }
                }
            }
        }
        .refreshable {
            await gradeManager.fetchEnrollments()
        }
    }
}

