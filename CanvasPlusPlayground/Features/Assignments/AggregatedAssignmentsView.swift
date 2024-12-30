//
//  AggregatedAssignmentsView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/18/24.
//

import SwiftUI

struct AggregatedAssignmentsView: View {
    @Environment(CourseManager.self) var courseManager
    @State var courseAssignments: [(Assignment, Course)] = []

    var body: some View {
        List {
            ForEach(courseAssignments, id:\.0.id) { assignment, course in
                AggregatedAssignmentsListCell(assignment: assignment, course: course)
            }
            .onMove { old, new in
                self.courseAssignments.move(fromOffsets: old, toOffset: new)
            }
        }
        .navigationTitle("Your Assignments")
        .task {

            for course in courseManager.userFavCourses {
                let assignments = await CourseAssignmentManager.getAssignmentsForCourse(courseID: course.id)

                for assignment in assignments {
                    if !(assignment.hasSubmittedSubmissions ?? false) {
                        self.courseAssignments.append((assignment, course))
                    }

                }
            }
        }
    }

}
