//
//  AggregatedAssignmentsView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/23/24.
//

import SwiftUI

struct AggregatedAssignmentsView: View {
    
    var courseManager: CourseManager
    @State var model: AggregatedAssignmentsViewModel
    
    init(courseManager: CourseManager) {
        self.courseManager = courseManager
        self.model = AggregatedAssignmentsViewModel(courses: courseManager.courses)
        
    }
    
    var body: some View {
        
        List {
            ForEach(model.assignments, id:\.0.id) { assignment, course in
                AggregatedAssignmentsListCell(assignment: assignment, course: course)
            }
            .onMove { old, new in
                model.assignments.move(fromOffsets: old, toOffset: new)
            }
        }
        .navigationTitle("Your Assignments")
        .task {
            print("Is anything happening")
            await model.loadAssignments()
        }
    }
    
}
