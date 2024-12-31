//
//  AggregatedAssignmentsListCell.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/24/24.
//

import SwiftUI

struct AggregatedAssignmentsListCell: View {
    let assignment: Assignment
    let course: Course

    var body: some View {
        VStack(alignment: .leading) {
            Text(assignment.name)

            Text("\(course.displayName)")
                .font(.subheadline)

        }
    }
}
