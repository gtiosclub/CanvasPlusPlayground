//
//  CourseGradeView.swift
//  CanvasPlusPlayground
//
//  Created by Songyuan Liu on 9/16/24.
//

import SwiftUI

struct CourseGradeView: View {
    @Environment(ProfileManager.self) private var profileManager
    @State private var gradesVM: GradesViewModel
    
    var enrollment: Enrollment? {
        gradesVM.enrollment
    }
    
    let course: Course
    
    
    init(course: Course) {
        self.course = course
        self._gradesVM = State(initialValue: GradesViewModel(courseId: course.id))
    }
    
    var body: some View {
        List {
            display("Current Score", value: enrollment?.grades?.currentScore)
            display("Current grade", value: enrollment?.grades?.currentGrade)
            display("Final Score", value: enrollment?.grades?.finalScore)
            display("Final Grade", value: enrollment?.grades?.finalGrade)
        }
        .task {
            await gradesVM
                .getEnrollments(currentUserID: profileManager.currentUser?.id)
        }
        .navigationTitle("Grades")
    }
    
    func display(_ label: String, value: Any?) -> Text {
        if let value = value {
            return Text("\(label): \(value)")
        } else {
            return Text("\(label) unavailable")
        }
    }
}

