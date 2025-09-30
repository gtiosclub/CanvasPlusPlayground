//
//  CourseHomePage.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/25.
//

import SwiftUI

struct CourseHomePage: View {
    let course: Course

    var body: some View {
        switch course.defaultView {
        case .assignments:
            CourseAssignmentsView(course: course)
        case .modules:
            ModulesListView(courseId: course.id)
        case .wiki:
            WikiFrontPage(course: course)
        case .syllabus:
            SyllabusView(course: course)
        case .feed:
            // FIXME: Implement Activity Stream
            unavailableView
        default:
            unavailableView
        }
    }

    private var unavailableView: some View {
        ContentUnavailableView(
            "Unsupported Home Page",
            systemImage: .questionmark
        )
        .navigationTitle(course.displayName)
    }
}
