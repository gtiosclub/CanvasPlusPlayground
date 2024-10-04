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
        VStack {
            ScrollView {
                
                Text("Grade Overview")
                    .font(.largeTitle)
                display("Current Score", value: enrollment?.grades?.currentScore)
                display("Current grade", value: enrollment?.grades?.currentGrade)
                display("Final Score", value: enrollment?.grades?.finalScore)
                display("Final Grade", value: enrollment?.grades?.finalGrade)
                
                
                Text("All submissions' Scores")
                    .font(.title)
                ForEach(courseManager.submissions, id: \.id) { submission in
                    display("Submission \(submission.id)'s score: ", value: submission.score)
                }
                
                Text("Key Info in Syllabus")
                    .font(.title)
                
                Text("Your Expected Grade of this Course")
                    .font(.title)
                
                Text("The next assignment's lowest score")
                    .font(.title)
            }
            .padding()
        }
        .padding()

        .task {
            await courseManager.getSubmissions(courseId: course.id)
            print(courseManager.submissions)
            await courseManager.getSyllabus(courseId: course.id)
            print(courseManager.syllabus)
            
        }
        .refreshable {
            await courseManager.getCourses()
            await courseManager.getSubmissions(courseId: course.id)
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

