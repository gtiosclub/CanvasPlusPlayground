//
//  AssignmentDetailView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 2/7/25.
//

import SwiftUI

struct AssignmentDetailView: View {
    let assignment: AssignmentAPI
    var body: some View {
        Form {
            Section {
                Text("Assignment Name: \(assignment.name)")
            }
            Section {
                Text("Due: \(assignment.dueDate?.formatted() ?? "NULL_DATE")")
                Text("Points: \(assignment.points_possible ?? -1)")
                Text("File Types: \(assignment.submission_types?.debugDescription ?? "NULL_FILE_TYPES")")
                Text(assignment.description?.stripHTML() ?? "missing description")
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    AssignmentDetailView(assignment: AssignmentAPI.example)
}
