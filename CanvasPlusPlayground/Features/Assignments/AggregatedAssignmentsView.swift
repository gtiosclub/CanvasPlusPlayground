//
//  AggregatedAssignmentsView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/18/24.
//

import SwiftUI

struct AggregatedAssignmentsView: View {
    @Environment(CourseManager.self) private var courseManager

    @State private var viewModel = AggregatedAssignmentsViewModel()

    var body: some View {
        List {
            ForEach(viewModel.assignments, id: \.0.id) { assignment, course in
                AggregatedAssignmentsListCell(assignment: assignment, course: course)
            }
            .onMove { old, new in
                viewModel.assignments.move(fromOffsets: old, toOffset: new)
            }
        }
        .navigationTitle("Your Assignments")
        .task {
            await viewModel
                .loadAssignments(courses: courseManager.userCourses)
        }
    }
}
