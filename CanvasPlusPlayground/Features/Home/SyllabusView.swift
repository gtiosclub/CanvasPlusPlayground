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
                    .pickedItem(AnyPickableItem(name: "Syllabus", contents: syllabusBody))
            } else {
                ContentUnavailableView(
                    "Could not load syllabus",
                    systemImage: .exclamationmarkTriangleFill
                )
            }
        }
        .navigationTitle("Syllabus")
    }
}
