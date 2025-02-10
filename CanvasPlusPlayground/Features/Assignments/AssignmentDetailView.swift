//
//  AssignmentDetailView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 2/7/25.
//

import SwiftUI

struct AssignmentDetailView: View {
    let assignment: AssignmentAPI
    init(assignment: AssignmentAPI) {
        self.assignment = assignment
    }
    var body: some View {
        if assignment.isOnlineQuiz {
            WebView(url: URL(string: assignment.html_url ?? "gatech.edu")!)
        } else {
            Form {
                Section {
                    LabeledContent("Name", value: assignment.name)
                }
                Section {
                    LabeledContent("Due", value: assignment.dueDate?.formatted() ?? "NULL_DATE")
                    LabeledContent("Points", value: String(format: "%.0f", assignment.points_possible ?? -1))
                    LabeledContent("File Types", value: assignment.allowed_extensions?.joined(separator: ", ") ?? "NULL_FILE_TYPES")
                }
                Section {
                    HTMLTextView(htmlText: assignment.description ?? "")
                }
            }
            .formStyle(.grouped)
        }
    }
}

#Preview {
    AssignmentDetailView(assignment: AssignmentAPI.example)
}
