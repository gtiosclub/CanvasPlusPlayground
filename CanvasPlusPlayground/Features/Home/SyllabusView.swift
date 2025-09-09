//
//  SyllabusView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/25.
//

import SwiftUI

struct SyllabusView: View {
    let course: Course

    var body: some View {
        Group {
            if let syllabusBody = course.syllabusBody {
                HTMLView(html: syllabusBody, courseID: course.id)
            } else {
                ContentUnavailableView(
                    "Could not load syllabus",
                    systemImage: "exclamationmark.triangle.fill"
                )
            }
        }
        .navigationTitle("Syllabus")
    }
}
