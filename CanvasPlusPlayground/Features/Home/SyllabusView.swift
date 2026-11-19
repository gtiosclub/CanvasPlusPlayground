//
//  SyllabusView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/25.
//

import SwiftUI

struct SyllabusView: View {
    let course: Course

    @State private var showExamDates = false

    var body: some View {
        Group {
            if let syllabusBody = course.syllabusBody {
                HTMLView(html: syllabusBody, courseID: course.id)
                    .pickedItem(AnyPickableItem(name: "Syllabus", contents: syllabusBody))
            } else {
                ContentUnavailableView(
                    "Could not load syllabus",
                    systemImage: "exclamationmark.triangle.fill"
                )
            }
        }
        .toolbar {
            if course.syllabusBody != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button("Find Exam Dates", systemImage: "calendar.badge.plus") { showExamDates = true }
                }
            }
        }
        .sheet(isPresented: $showExamDates) {
            NavigationStack {
                ExamDatesView(course: course)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showExamDates = false }
                        }
                    }
            }
        }
        #if os(iOS)
        .navigationTitle("Syllabus")
        #else
        .navigationTitle("\(course.displayName) -- Syllabus")
        #endif
    }
}
