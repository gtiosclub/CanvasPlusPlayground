//
//  PeopleCommonView.swift
//  CanvasPlusPlayground
//
//  Created by Max Ko on 10/2/24.
//

import SwiftUI

struct PeopleCommonView: View {
    @Environment(PeopleManager.self) var peopleManager
    let user: User
    @State var courses: [Course] = []
    @State private var loading: Bool = false

    var body: some View {
        Form {
            Section {
                statusLabel
            } footer: {
                if !peopleManager.allCoursesCached {
                    Text("Showing only results from cached courses")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                ForEach(courses, id: \.id) { course in
                    Text(course.name ?? "")
                }
            } header: {
                Text("Courses")
            }
        }
        .task {
            loading = true
            self.courses = await peopleManager.fetchAllClassesWith(userID: user.id!)
            loading = false
        }
        .formStyle(.grouped)
    }

    private var statusLabel: some View {
        HStack {
            Text("Common Courses")

            Spacer()

            if loading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Text("\(courses.count)")
                    .bold()
            }
        }
    }
}

