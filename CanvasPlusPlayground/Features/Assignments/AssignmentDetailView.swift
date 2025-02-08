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
                HStack {
                    Text("Assignment Name")
                    Spacer()
                    Text(assignment.name)
                }
                
            }
            Section {
                HStack {
                    Text("Due")
                    Spacer()
                    Text(assignment.dueDate?.formatted() ?? "NULL_DATE")
                }
                HStack {
                    Text("Points")
                    Spacer()
                    Text(String(format: "%.0f", assignment.points_possible ?? -1))
                }
                HStack {
                    Text("File Types")
                    Spacer()
                    Text(assignment.submission_types?.joined(separator: ", ") ?? "NULL_FILE_TYPES")
                }
                
            }
            Section {
                HTMLTextView(htmlText: assignment.description ?? "")
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    AssignmentDetailView(assignment: AssignmentAPI.example)
}
